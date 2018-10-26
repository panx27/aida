#!/usr/bin/perl

use warnings;
use strict;

binmode(STDOUT, ":utf8");

### DO NOT INCLUDE
use PoolResponsesManagerLib;
use POSIX;

### DO INCLUDE
##################################################################################### 
# This program takes as input: 
#   (1) A single pooler output file, and
#   (2) The max number of elements to go in a single kit,
# and produces as output a set of kits as desired by LDC.
#
# Author: Shahzad Rajput
# Please send questions or comments to shahzadrajput "at" gmail "dot" com
#
# For usage, run with no arguments
##################################################################################### 

my $version = "2018.0.0";

# Filehandles for program and error output
my $program_output = *STDOUT{IO};
my $error_output = *STDERR{IO};

# Subroutines

sub get_docid {
	my ($line) = @_;
	my @elements = split(/\t/, $line);
	$elements[4];
}

##################################################################################### 
# Runtime switches and main program
##################################################################################### 

# Handle run-time switches
my $switches = SwitchProcessor->new($0, "Generate kits from the single pool file for LDC",
				    						"");
$switches->addHelpSwitch("help", "Show help");
$switches->addHelpSwitch("h", undef);
$switches->addVarSwitch('error_file', "Specify a file to which error output should be redirected");
$switches->put('error_file', "STDERR");
$switches->addVarSwitch('prefix', "Specify the prefix of the output kits");
$switches->put('prefix', "kits");
$switches->addImmediateSwitch('version', sub { print "$0 version $version\n"; exit 0; }, "Print version number and exit");
$switches->addVarSwitch('m', "How large can the kit be? This value is provided by LDC.");
$switches->put('m', "200");
$switches->addParam("uid_info", "required", "uid_info.tab file from LDC");
$switches->addParam("pool", "required", "File containing pool");
$switches->addParam("kit_language_map", "required", "Output file containing kit to language mapping");
$switches->addParam("output", "required", "Kits output directory");

$switches->process(@ARGV);

my $logger = Logger->new();
my $error_filename = $switches->get("error_file");
$logger->set_error_output($error_filename);
$error_output = $logger->get_error_output();

my $pool_filename = $switches->get("pool");
$logger->NIST_die("$pool_filename does not exist") unless -e $pool_filename;

my $output_dir = $switches->get("output");
$logger->NIST_die("$output_dir already exists")
		if(-e $output_dir);
system("mkdir $output_dir");

my $kit_language_map_filename = $switches->get("kit_language_map");
$logger->NIST_die("$kit_language_map_filename already exists")
	if(-e $kit_language_map_filename);
open(my $kit_language_map_output, ">:utf8", $kit_language_map_filename)
	or $logger->NIST_die("Could not open $kit_language_map_filename: $!");

my %docid_to_languages;
my $uid_info_filename = $switches->get("uid_info");
$logger->NIST_die("$uid_info_filename does not exist") unless -e $uid_info_filename;
my $filehandler = FileHandler->new($logger, $uid_info_filename);
foreach my $entry($filehandler->get("ENTRIES")->toarray()) {
	my $docid = $entry->get("uid");
	my $languages = $entry->get("lang_id");
	$docid_to_languages{$docid}{$languages} = 1;
}

my $max_kit_size = $switches->get("m");
my $prefix = $switches->get("prefix");

my $pool = Pool->new($logger, $pool_filename);

my ($num_errors, $num_warnings) = $logger->report_all_information();
unless($num_errors+$num_warnings) {
	my %languages_in_kit;
	foreach my $kb_id($pool->get("ALL_KEYS")) {
 		my $kit = $pool->get("BY_KEY", $kb_id);
 		my $total_entries = scalar($kit->toarray());
 		my $total_kits = ceil($total_entries/$max_kit_size);
		my @kit_entries = sort {get_docid($a) eq get_docid($b)} $kit->toarray();
 		my $linenum = 0;
 		for(my $kit_num = 1; $kit_num <=$total_kits; $kit_num++){
 			my $output_filename = "$output_dir/kit_$kb_id\_$kit_num\_$total_kits\.tab";
 			open(my $program_output, ">:utf8", $output_filename) or $logger->NIST_die("Could not open $output_filename: $!");
 			for(my $i=($kit_num-1)*$max_kit_size; $i<$kit_num*$max_kit_size && $i<$total_entries; $i++) {
 				$linenum++;
 				my $output_line = $kit_entries[$i];
 				$output_line =~ s/<ID>/$linenum/;
 				print $program_output "$output_line\n";
				# collect the languages in this kit partition
				my @entries = split(/\t/, $output_line);
				my $docid = $entries[4];
				foreach my $languages_in_doc(keys %{$docid_to_languages{$docid}}) {
					foreach my $language_in_doc(split(/,/, $languages_in_doc)) {
						$languages_in_kit{$kb_id}{$language_in_doc} = 1;
					}
				}
 			}
 			close($program_output);
 		}
	}
	foreach my $kb_id(keys %languages_in_kit) {
		my @languages = sort keys %{$languages_in_kit{$kb_id}};
		my $languages = join(",", @languages);
		print $kit_language_map_output "$kb_id\t$languages\n";
	}
	close($kit_language_map_output);
}

unless($switches->get('error_file') eq "STDERR") {
	print STDERR "Problems encountered (warnings: $num_warnings, errors: $num_errors)\n" if ($num_errors || $num_warnings);
	print STDERR "No warnings encountered.\n" unless ($num_errors || $num_warnings);
}

print $error_output ($num_warnings || 'No'), " warning", ($num_warnings == 1 ? '' : 's'), " encountered.\n";
exit 0;
