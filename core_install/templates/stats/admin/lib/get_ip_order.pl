#!/usr/bin/perl -w

# ********************************************************************
# Ericsson                                                      SCRIPT
# ********************************************************************
#
#
# (c) Ericsson 2011 - All rights reserved.
#
# The copyright to the computer program(s) herein is the property
# of Ericsson Radio Systems AB, Sweden. The programs may be used
# and/or copied only with the written permission from Ericsson Radio
# Systems AB or in accordance with the terms and conditions stipulated
# in the agreement/contract under which the program(s) have been
# supplied.
#
# ********************************************************************
# Name    : get_ip_order.pl
# Date    : 14/05/2012
# UserID  : EEIACN
# Purpose : This script will get the installation order of the servers  
# Usage   : see display_help functions
#
# ********************************************************************
#
#   Command Section
#
# ********************************************************************

use strict;
use Getopt::Std;
use Sys::Hostname;

# declare the perl command line flags/options we want to allow
my %args=();
my $test_dir;
my $debug;
my $output_file;
my $test_hostname;
#This is the mapper for multiple servers install types installed
my %order_helper = ( 'eniq_iqr', 'reader_[0-9]+$', 'eniq_mz', 'ec_[0-9]+', 'stats_iqr', 'reader_[0-9]+');
my @ordered_ips;

getopts("z:y:h:f:x", \%args);

if(defined $args{f} ) { $output_file   = $args{f}; }

#Theses args are for testing
if(defined $args{z} ) { $test_dir   = $args{z}; }
if(defined $args{y} ) { $test_hostname   = $args{y}; }
if(defined $args{x} ) { $debug="yes"; }



my $eniq_base="/eniq";
my $eniq_install=$eniq_base."/installation";
my $eniq_sw=$eniq_base."/sw";
my $eniq_sw_cfg=$eniq_sw."/conf";
my $eniq_cfg_install=$eniq_install."/config";
my $eniq_core_install=$eniq_install."/core_install";
my $eniq_core_install_etc=$eniq_core_install."/etc";
my $eniq_use_config="/ericsson_use_config";
my $server_types="/server_types";
my $service_names="/service_names";
my $hostname = hostname;
if(defined $test_dir ) 
{ 
$eniq_cfg_install =$test_dir; 
$eniq_sw_cfg =$test_dir;
$eniq_core_install_etc=$test_dir;
$hostname=$test_hostname;
}
$hostname=$hostname="::".$hostname."::";
my $eniq_config_file=$eniq_cfg_install.$eniq_use_config;
my $server_types_file=$eniq_sw_cfg.$server_types;
my $service_names_file=$eniq_sw_cfg.$service_names;
my $server_type=get_server_type($eniq_config_file);
my $stats_server_list="/".$server_type."_server_list";
my $stats_server_list_file=$eniq_core_install_etc.$stats_server_list;

if( ! defined $output_file)
{
   display_help();
   exit(1);
}


  
my @server_list=read_file( "$stats_server_list_file");
print_debug ("\n=============$stats_server_list_file================\n");
print_debug ("@server_list\n");

my @server_types=read_file( "$server_types_file");

print_debug ("\n===========$server_types_file==================\n");
print_debug ("@server_types\n");

my @service_names=read_file( "$service_names_file");

print_debug ("\n============$service_names_file=================\n");
print_debug ("@service_names\n");



foreach my $ser_list (@server_list){
	my @server_type= split("::", $ser_list);
	print_debug ("========");
	print_debug ("server type to be ordered is $server_type[0] \n");
	#use the first value in _server_list line(stats_coordinator...etc) to grep
	my @types_details = grep(/$server_type[0]$/, @server_types);
		if( scalar(@types_details) == 1)
		{
			push (@ordered_ips,$types_details[0])
		}elsif( scalar(@types_details) > 1)
		{
			print_debug ("server type to send to order_type $server_type[0]\n");
			order_type($server_type[0])
		}
}
if( scalar(@server_types) != scalar(@ordered_ips)) {
	error ("number of server_types in $server_types_file does not match ordered ip");
}

print_debug ("\n================orde with self=============\n");
open(FILE, ">$output_file") || die "$!  $_[0]";
foreach my $server (@ordered_ips){
	#if($server !~ m/($hostname)/)
	#{
	 print FILE "$server\n";
	print_debug ("$server\n");
	#}
}
close (FILE);





########################################################################
# display_help
########################################################################

sub display_help
{
  
   print "\n\n\n****************************************";
   print "\n Help -- Valid Options\n";
   print "\n -f output file";
   print "\n -h <Display Usage>";
   print "\nThis script gets the order of installation.\n";
   print "\nIt uses the following files to determine the order of installation";
   print "\n$stats_server_list_file";
   print "\n$server_types_file";
   print "\n$service_names_file";
   print "\nThe $stats_server_list_file will be used to determine the order of how the server were installed";
   print "\nThe $server_types_file and $service_names_file are used to get the ips";
   print "\n\n****************************************\n";
}
########################################################################
# error
########################################################################

sub error
{
	my ($msg) = @_;
	print "$msg\n";
	exit(45);
}
########################################################################
# print_debug
########################################################################

sub print_debug
{
	if ( defined $debug && $debug eq "yes")
	{
		my ($msg) = @_;
		print "$msg\n";
	}
}
################################################################
#  read_file
###############################################################

sub read_file
{

my @file;
  open(CONFIG, "< $_[0]") || die "$!  $_[0]";  
  
   while (<CONFIG>) {
    #print;
    chomp;                  # no newline
    s/#.*//;                # no comments
    s/^\s+//;               # no leading white
    s/\s+$//;               # no trailing white
    next unless length;     # anything left?
	push (@file,$_);
	}    
	return @file;
  close(CONFIG);
}
################################################################
# get_server_type
###############################################################
sub get_server_type
{
	my ($file) = @_;
	my @config_file=read_file("$file");
	if( scalar(@config_file) == 1)
	{
		print_debug "here $config_file[0]\n";
		my ($var,$value) = split(/\s*=\s*/, $config_file[0], 2);
		print_debug "$var,$value any thing\n";
		return $value;
	}else{
		error ("error getting server_type");
	}

}

################################################################
# order_type
# uses global variables ordered_ips, service_names and order_helper
###############################################################
sub order_type
{
	my ($type) = @_;
	my $server_type;
	my %servers_hash;
	while ((my $key, my $value) = each(%order_helper)){
		if( $type eq $key )
		{
			 print_debug ("$type   $key,  $value\n");
			$server_type=$value;
		} 
	}
	if (defined $server_type && $server_type ne '') {
		my @servers = grep(/($server_type)/, @service_names);
		if( scalar(@servers) == 0){
			error ("couldn't map $type to anything in service_name file using $server_type");
		}
		foreach my $ser_type (@servers){
			my @values = split('::', $ser_type);
			$servers_hash{$values[2]} = $ser_type;	
		}
		foreach my $key (sort keys %servers_hash) {
			push (@ordered_ips,$servers_hash{$key});
		}
	}else{
		error ("couldn't map $type to anything in service_name file");
	}


}


