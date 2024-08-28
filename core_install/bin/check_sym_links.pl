#!/usr/bin/perl -w

# ********************************************************************
# Ericsson                                                      SCRIPT
# ********************************************************************
#
#
# (c) Ericsson 2016 - All rights reserved.
#
# The copyright to the computer program(s) herein is the property
# of Ericsson Radio Systems AB, Sweden. The programs may be used
# and/or copied only with the written permission from Ericsson Radio
# Systems AB or in accordance with the terms and conditions stipulated
# in the agreement/contract under which the program(s) have been
# supplied.
#
# ********************************************************************
# Name    : check_sym_links.pl
# Date    : 09/06/2016
# UserID  : EOLIMCG
# Purpose : This script will determine if the sym_links.ini file is correct in  #           the /eniq/installation/config dir
#           
#
# Usage   : ./check_sym_links.pl sym_links.ini
#
# ********************************************************************
#
#   Command Section
#
# ********************************************************************

use strict;
use Getopt::Std;

# declare the perl command line flags/options we want to allow
my %options=();
getopts("h", \%options);

#print "-h $options{h}\n" if defined $options{h};

if ($options{h})
{
  do_help();
}

sub do_help
{
  print "usage: ./check_sym_links.pl sym_links.ini 
    -h              : this (help) message \n";
	die "$? \n";
}

# check for sym_links.ini file
if (-f $ARGV[0])
{
	open(MYINPUTFILE, "$ARGV[0]")
}
else
{
	print "Required file sym_links.ini is not present in the command line \n";
	do_help();
	 
	 

}

my(@lines) = <MYINPUTFILE>;
close(MYINPUTFILE);
my($line);

my @dwh_main;
my @dwh_tmp;
my @dwh_main_bracket;
my @dwh_tmp_bracket;
my @dwh_sym;
my @dwh_sym_bracket;
my @links;
my @luns;
my $error_code=0;

#This function get child heading for a ini file
sub ini_child
{
        my $parent = $_[0];
		my $child  = join("","\\[",$parent,"_","\\d\+]");
        return $child;
}


#This function fills the arrays with details from sym links ini file
sub fillArray 
{
        my $argument = $_[0];
        my @array ;
                foreach $line(@lines)
                {
					if($line =~ m/^$argument/)
					{
					  push @array, $line;
					}
                }
        return @array;
}

#Function to format arrays
sub formatArray
{
my @array = @_;
@array = grep(s/\[//, @array);
@array = grep(s/]//, @array);
        return @array;
}


#This function checks if the references are correct in the sym_links.ini file
sub checkReference
{
        my($array1, $array2) = @_;
		for(my $i=0;$i<@{$array1};$i++)
        {
                if(@{$array1}[$i] eq @{$array2}[$i])
                {
                        print "The references for @{$array1}[$i] is correct\n";
                }
                else
                {
                        print "THE REFERENCE FOR @{$array1}[$i] ARE INCORRECT!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! \n";
						$error_code=22;
                }
        }
}


#Fill the arrays
my $DWH_DBSPACES_MAIN="DWH_DBSPACES_MAIN";
my $DWH_DBSPACES_MAIN_CHILD=ini_child($DWH_DBSPACES_MAIN);
my $DWH_DBSPACES_TEMP="DWH_DBSPACES_TEMP";
my $DWH_DBSPACES_TEMP_CHILD=ini_child($DWH_DBSPACES_TEMP);
my $DWH_SYS_MAIN="DWH_SYSTEM_MAIN";
my $DWH_SYS_MAIN_CHILD=ini_child($DWH_SYS_MAIN);

@dwh_main = sort(fillArray($DWH_DBSPACES_MAIN)); 
@dwh_main_bracket = fillArray($DWH_DBSPACES_MAIN_CHILD);
@dwh_tmp = sort(fillArray($DWH_DBSPACES_TEMP));
@dwh_tmp_bracket =fillArray($DWH_DBSPACES_TEMP_CHILD);
@dwh_sym = sort(fillArray($DWH_SYS_MAIN));
@dwh_sym_bracket = fillArray($DWH_SYS_MAIN_CHILD);
@links = fillArray('(Link)');
@luns = `/ericsson/storage/san/bin/blkcli --action listluns`;
if (!@luns) 
{
	print "ERROR: Unable to get list of LUNS \n";
	$error_code=1;
	exit  $error_code;
}




#Format the arrays
@dwh_main_bracket = sort(formatArray(@dwh_main_bracket));
@dwh_tmp_bracket = sort(formatArray(@dwh_tmp_bracket));
@dwh_sym_bracket = sort(formatArray(@dwh_sym_bracket));
@links = grep(s/Link=\/.{3}\/.{4}\///, @links);
@links = grep(s/.{2}$//, @links);
@luns = grep(s/.*?;//, @luns);
@luns = grep(s/;.*//, @luns);


checkReference(\@dwh_main, \@dwh_main_bracket);
checkReference(\@dwh_tmp,\@dwh_tmp_bracket);
checkReference(\@dwh_sym,\@dwh_sym_bracket);

#This function checks to make sure that the disks listed are present in the list of luns
for(my $k=0;$k<@links;$k++)
{
	if(grep(/$links[$k]/,@luns))
    {
		print "The disk $links[$k] is present in the list of luns \n";
	}
	else 
	{
		print "THE DISK $links[$k] IS NOT PRESENT IN THE LIST OF LUNS!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! \n";
		$error_code=32;
	}
}

if ( $error_code > 0 ) 
{
	exit  $error_code;
}


