#!/usr/bin/perl

use warnings;
use strict;

binmode(STDOUT, ":utf8");

### DO NOT INCLUDE
use ResolveQueriesManagerLib;

### DO INCLUDE
##################################################################################### 
# This program validates applies AIDA queries to KBs in order to generate
# submissions. It takes as input the evaluation queries, a directory containing
# KBs split across TTL files in case of a TA1 submission, and a output directory. 
# In case of a TA2 systems, the submission is in the form of a single TTL file. 
#
# Author: Shahzad Rajput
# Please send questions or comments to shahzadrajput "at" gmail "dot" com
#
# For usage, run with no arguments
##################################################################################### 

my $version = "2018.0.0";

##################################################################################### 
# Runtime switches and main program
##################################################################################### 

# Handle run-time switches
my $switches = SwitchProcessor->new($0, "Apply a set of SPARQL evaluation queries to a knowledge base \
											in Turtle RDF format to produce AIDA output for assessment.",
				    						"");
$switches->addHelpSwitch("help", "Show help");
$switches->addHelpSwitch("h", undef);
$switches->addVarSwitch('error_file', "Specify a file to which error output should be redirected");
$switches->put('error_file', "STDERR");
$switches->addVarSwitch('sparql', "Specify path to SPARQL executable");
$switches->put('sparql', "sparql");
$switches->addImmediateSwitch('version', sub { print "$0 version $version\n"; exit 0; }, "Print version number and exit");
$switches->addParam("queries_dtd", "required", "DTD file corresponding to the XML file containing queries");
$switches->addParam("queries_xml", "required", "XML file containing queries");
$switches->addParam("input", "required", "File containing the KB (for TA2 system) or directory containing KBs (for TA1 system).");
$switches->addParam("intermediate", "required", "Specify a directory to be used for storing intermediate files.");
$switches->addParam("output", "required", "Specify an output directory.");

$switches->process(@ARGV);

my $logger = Logger->new();
my $error_filename = $switches->get("error_file");
$logger->set_error_output($error_filename);
my $error_output = $logger->get_error_output();

foreach my $path(($switches->get("sparql"), $switches->get("queries_dtd"), $switches->get("queries_xml"), $switches->get("input"))) {
	$logger->NIST_die("$path does not exist") unless -e $path;
}

foreach my $path(($switches->get("intermediate"), $switches->get("output"))) {
	$logger->NIST_die("$path already exists") if -e $path;
}

my $parameters = Parameters->new($logger);
$parameters->set("QUERIES_DTD_FILE", $switches->get("queries_dtd"));
$parameters->set("QUERIES_XML_FILE", $switches->get("queries_xml"));
$parameters->set("INPUT", $switches->get("input"));
$parameters->set("INTERMEDIATE_DIR", $switches->get("intermediate"));
$parameters->set("OUTPUT_DIR", $switches->get("output"));
$parameters->set("SPARQL_EXECUTABLE", $switches->get("sparql"));

my $queries = Queries->new($logger, $parameters);
# Load the DTD file followed by the XML file
$queries->load();
# Generate RQ files
$queries->transform();
# Resolve queries against KB(s)
$queries->resolve();

my ($num_errors, $num_warnings) = $logger->report_all_information();
print "Problems encountered (warnings: $num_warnings, errors: $num_errors)\n" if ($num_errors || $num_warnings);
print "No problems encountered.\n" unless ($num_errors || $num_warnings);
print $error_output ($num_warnings || 'No'), " warning", ($num_warnings == 1 ? '' : 's'), " encountered\n";
exit 0;