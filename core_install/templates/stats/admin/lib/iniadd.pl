#!/usr/bin/env perl

use strict;
use vars qw/ %opt /;
use Getopt::Std;
use Data::Dumper;

sub GETOPTIONS {
    my ${OPT_STR} = 'g:p:i:d:o:h ';
getopts( "${OPT_STR}", \%opt ) || die "ERROR : Unable to prcess the options $! \n";
USAGE () if ( ( (! $opt{g}) && (! $opt{p}) && (! $opt{i}) && (! $opt{o}) && (! $opt{d})) || ($opt{h}) );
}

sub USAGE {
    print STDERR << "EOF";

usage: $0 [-g <root tag>] -p <tag> -i <input file name> -o <output file name>
    -h              : this (help) message
    -g              : main tag
    -p                : secondary tag
    -d                : full path of data file containing the attributes and values.
    -i                : full path of input file.
    -o                : full path of output file.
example: $0 -g SUN_OS -p DISK -d /var/tmp/disk_attr -i /ericsson/config/system.ini -o /ericsson/config/system.ini.new
EOF
exit 9;
}

sub main 
{
    my $DEBUG = 0;

    GETOPTIONS ();
    ( -f "$opt{d}" ) && ( open (INPUT, "$opt{d}" ) || die "ERROR : Can't open $opt{d}.\n" ) || die "ERROR : $opt{d} not found.\n";
    ( ! -f "$opt{o}" ) && ( open (FFOUT, ">$opt{o}" ) || die "ERROR : Can't open $opt{o}.\n" ) || die "ERROR : $opt{o} file already exist.\n";
    
    my $inFile = $opt{i};
    my $outFile = $opt{o};
    my $dataFile = $opt{d};
    my $grandParent = $opt{g};
    my $parent = $opt{p};

    my $LOOK_FOR_GP = 0;
    my $LOOK_FOR_SIB_LIST = 1;
    my $LOOK_FOR_SIB_SECT_START = 2;
    my $LOOK_FOR_SIB_SECT_END = 3;
    my $LOOK_FOR_END = 4;

    my $state = $LOOK_FOR_GP;

    my %siblings = ();

    my $sect_name;

   
    open IN_FILE, $inFile or die "ERROR: Cannot open $inFile";
    open OUT_FILE, ">$outFile" or die "ERROR: Cannot open $outFile";
    while ( my $line = <IN_FILE> )
    {
	if ( $DEBUG > 5 ) { print "state=$state line=$line"; }

	if ( $state == $LOOK_FOR_GP )
	{
	    print OUT_FILE $line;
	    if ( $line =~ /^\[$grandParent\]$/ )
	    {
		$state = $LOOK_FOR_SIB_LIST;
	    }
	}
	elsif ( $state == $LOOK_FOR_SIB_LIST )
	{
	    if ( $line =~ /^(\S+)$/ )
	    {
		my $sib = $1;
		$siblings{$sib} = 1;

		# We'll alway put the parent at the end of the grandParent section
		if ( $sib ne $parent )
		{		    
		    print OUT_FILE $line;
		}
	    }
	    elsif ( $line =~ /^\s*$/ )
	    {
		print OUT_FILE "$parent\n";
		print OUT_FILE $line;

		my @remainingSibs = keys %siblings;
		if ( $#remainingSibs == -1 )
		{
		    # No other sibs
		    printData($dataFile);
		    $state = $LOOK_FOR_END;
		}
		else
		{
		    $state = $LOOK_FOR_SIB_SECT_START;
		}
	    }
	}
	elsif ( $state == $LOOK_FOR_SIB_SECT_START )
	{
	    if ( $line =~ /^\[(\S+)\]$/ )
	    {
		$sect_name = $1;
		if ( exists $siblings{$sect_name} )
		{
                    if ( $DEBUG > 5 ) { print "Found section $sect_name\n"; }
		    delete $siblings{$sect_name};
		}
		else
		{
		    die "ERROR: Unexpected section $sect_name";
		}
		
		$state = $LOOK_FOR_SIB_SECT_END;

		# Don't print the lines belonging to the parent section
		if ( $sect_name ne $parent )
		{
		    print OUT_FILE $line;
		}
	    }
	    else
	    {
		print OUT_FILE $line;
	    }

	}
	elsif ( $state == $LOOK_FOR_SIB_SECT_END )
	{
	    # Don't print the lines belonging to the parent section
	    if ( $sect_name ne $parent )
	    {
		print OUT_FILE $line;
	    }
	    
	    if ( ($line =~ /^\s*$/) || ($line =~ /^\;/) )
	    {
		my @remainingSibs = keys %siblings;
                if ( $DEBUG > 5 ) { print Dumper("reached end of section, remainingSibs", \@remainingSibs); }
		if ( $#remainingSibs == -1 )
		{
		    printData($dataFile);
		    $state = $LOOK_FOR_END;
		}
		else
		{
		    $state = $LOOK_FOR_SIB_SECT_START;
		}
	    }
	}
	elsif ( $state == $LOOK_FOR_END )
	{
	    print OUT_FILE $line;
	}
    }

    if ( $state != $LOOK_FOR_END )
    {
	my @remainingSibs = keys %siblings;
	if ( $#remainingSibs == -1 )
	{
	    printData($dataFile);
	}
	else
	{
	    die "ERROR: End of input reached while searching for sections";
	}
    }
    close OUT_FILE;
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
