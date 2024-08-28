#!/usr/bin/env perl

use strict;
use vars qw/ %opt /;
use Getopt::Std;
use Data::Dumper;

sub GETOPTIONS {
    my ${OPT_STR} = 'g:p:i:o:h ';
getopts( "${OPT_STR}", \%opt ) || die "ERROR : Unable to prcess the options $! \n";
USAGE () if ( ( (! $opt{g}) && (! $opt{p}) && (! $opt{i}) && (! $opt{o}) && (! $opt{d})) || ($opt{h}) );
}

sub USAGE {
    print STDERR << "EOF";

usage: $0 [-g <root tag>] -p <tag> -i <input file name> -o <output file name>
    -h              : this (help) message
    -g              : main tag
    -p                : secondary tag
    -i                : full path of input file.
    -o                : full path of output file.
example: $0 -g SUN_OS -p DISK -i /ericsson/config/system.ini -o /ericsson/config/system.ini.new
EOF
exit 9;
}

sub main 
{
    my $DEBUG = 0;

    GETOPTIONS ();
    ( ! -f "$opt{o}" ) && ( open (FFOUT, ">$opt{o}" ) || die "ERROR : Can't open $opt{o}.\n" ) || die "ERROR : $opt{o} file already exist.\n";
    
    my $inFile = $opt{i};
    my $outFile = $opt{o};
    my $grandParent = $opt{g};
    my $parent = $opt{p};

    my $LOOK_FOR_GP = 0;
    my $LOOK_FOR_SIB_LIST = 1;
    my $LOOK_FOR_SIB_SECT_START = 2;
    my $LOOK_FOR_SIB_SECT_END = 3;
    my $LOOK_FOR_END = 4;

    my $REMOVE_GRANDPARENT = 0;
    my $REMOVE_PARENT = 1;

    my $removeType;
    if ( defined $grandParent && ! defined $parent )
    {
	$removeType = $REMOVE_GRANDPARENT;
    }
    else
    {
	$removeType = $REMOVE_PARENT;
    }
    if ( $DEBUG > 5 ) { print "removeType=$removeType\n"; }

    my %siblings = ();
    my $state = $LOOK_FOR_GP;
    if ( defined $parent )
    {
	$siblings{$parent} = 1;
    }

    if ( ! defined $grandParent )
    {
	$state = $LOOK_FOR_SIB_SECT_START;	
    }

    my $sect_name;
   
    open IN_FILE, $inFile or die "ERROR: Cannot open $inFile";
    open OUT_FILE, ">$outFile" or die "ERROR: Cannot open $outFile";
    while ( my $line = <IN_FILE> )
    {
	if ( $DEBUG > 5 ) { print "state=$state line=$line"; }

	if ( $state == $LOOK_FOR_GP )
	{
	    if ( $line =~ /^\[$grandParent\]$/ )
	    {
		$state = $LOOK_FOR_SIB_LIST;

		# Don't print the grandParent if we are removing it
		if ( $removeType != $REMOVE_GRANDPARENT ) 
		{
		    print OUT_FILE $line;
		}
		else
		{
		    if ( $DEBUG > 3 ) { print "not printing line $line"; }
		}
	    }
	    else
	    {
		    print OUT_FILE $line;
	    }
	}
	elsif ( $state == $LOOK_FOR_SIB_LIST )
	{
	    if ( $line =~ /^(\S+)$/ )
	    {
		my $sib = $1;

		if ( $removeType != $REMOVE_GRANDPARENT &&
		     $sib ne $parent )
		{		    
		    print OUT_FILE $line;
		}
		else
		{
		    if ( $DEBUG > 3 ) { print "not printing line $line"; }
		}

		if ( $removeType == $REMOVE_GRANDPARENT )
		{
		    $siblings{$sib} = 1;
		}
	    }
	    else
	    {
		$state = $LOOK_FOR_SIB_SECT_START;
		print OUT_FILE $line;
	    }
	}
	elsif ( $state == $LOOK_FOR_SIB_SECT_START )
	{
	    if ( $line =~ /^\[(\S+)\]$/ )
	    {
		$sect_name = $1;
		if ($siblings{$sect_name} == 1 )
		{
		    $siblings{$sect_name} = 2;
                    if ( $DEBUG > 5 ) { print "Found section $sect_name\n"; }
		}
		else
		{
		    print OUT_FILE $line;
		}

		$state = $LOOK_FOR_SIB_SECT_END;

		# Don't print the lines belonging to the parent section
	    }
	    else
	    {
		print OUT_FILE $line;
	    }

	}
	elsif ( $state == $LOOK_FOR_SIB_SECT_END )
	{
	    if ( ! exists $siblings{$sect_name} )
	    {
		print OUT_FILE $line;
	    }
	    else
	    {
		if ( $DEBUG > 3 ) { print "not printing line $line"; }
	    }

	    
	    if ( ($line =~ /^\s*$/) || ($line =~ /^\;/) )
	    {
		$state = $LOOK_FOR_SIB_SECT_START;
	    }
	}
	elsif ( $state == $LOOK_FOR_END )
	{
	    print OUT_FILE $line;
	}
    }

    close OUT_FILE;

    my $result = 0;
    foreach my $sib ( keys %siblings )
    {
	if ( $siblings{$sib} != 2 )
	{
	    print "ERROR: Failed to delete $sib\n";
	    $result = 1;
	}
    }
    return $result;
}

sub printData()
{
    my ($dataFile) = @_;

    open DATA_FILE, $dataFile or die "ERROR: Cannot open $dataFile";
    my @dataLines = <DATA_FILE>;
    close DATA_FILE;
    
    print OUT_FILE "\n";
    print OUT_FILE @dataLines;
    print OUT_FILE "\n";

}	


main();
