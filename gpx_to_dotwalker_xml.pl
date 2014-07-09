#!/usr/bin/perl
#
# by Matija Nalis <mnalis-blind@voyager.hr> GPLv3+ started 2014-07-09
# home at https://github.com/mnalis/gpx_to_dotwalker_xml
#
# command line version
#
# Creates XML for Dotwalker (GPS application for blind people) from .gpx
# Use extended format routing GPX  from for example http://graphhopper.com/maps/
#
# requires XML::LibXML perl module ("apt-get install libxml-libxml-perl")

use strict;
use warnings;
use autodie;
#use diagnostics;

my $DEBUG = 0;
my $whitespace = 0;	# 1/2 for debug, 0 for production (no spaces)

use XML::LibXML;
local $XML::LibXML::setTagCompression = 1;	# As we don't know if Dotwalker supports <Description /> short-empty-tag, use the value we know it supports <Description></Description>
binmode STDOUT, ':utf8';	# our terminal is UTF-8 capable (we hope)

my $VERSION = '0.3';

my $fname_GPX = $ARGV[0];
my $fname_XML = $ARGV[1];

if (!defined ($fname_GPX) or !defined($fname_XML)) {
    print "gpx_to_dotwalker_xml.pl v$VERSION\n";
    print "Usage: $0 <input.GPX> <output.XML>\n\n";
    print "input or/and output file can be '-', signifying stdin/stdout\n";
    print "This program Creates XML for Dotwalker from .GPX\n";
    exit 1;
}

# create empty dotwalker .xml 
my $xmldom = XML::LibXML::Document->new('1.0', 'utf-8');
$xmldom->setStandalone(1);
my $xmlroot = $xmldom->createElement('Route');

# parse given .gpx
my $parser = XML::LibXML->new();
my $gpxdom = $parser->parse_file($fname_GPX);
my @rte = $gpxdom->getElementsByTagName('rtept');


$DEBUG && print "Parsing from GPX $fname_GPX to Dotwalker XML $fname_XML\n\n";
foreach my $rtept (@rte) {
  use Data::Dumper;
  my $lat = $rtept->getAttribute('lat');
  my $lon = $rtept->getAttribute('lon');
  my $title = $rtept->getElementsByTagName('desc')->string_value;	# FIXME: does it work if <desc> is not present?
  my $desc = '';	# FIXME - do something smarter from <extensions> tag (if present) (and check if it works when not present)
  
  $DEBUG && print "parsing RTEPT: lat=$lat, lon=$lon title=$title desc=$desc\n";

  my $x_point = $xmldom->createElement('Point');
  my $x_title = $xmldom->createElement('Title'); $x_title->appendTextNode($title); $x_point->appendChild($x_title);
  my $x_lat = $xmldom->createElement('Lat'); $x_lat->appendTextNode($lat); $x_point->appendChild($x_lat);
  my $x_lon = $xmldom->createElement('Lng'); $x_lon->appendTextNode($lon); $x_point->appendChild($x_lon);
  my $x_desc = $xmldom->createElement('Description'); $x_desc->appendTextNode($desc); $x_point->appendChild($x_desc);
  $xmlroot->appendChild($x_point);
}


$xmldom->setDocumentElement($xmlroot);
$xmldom->toFile($fname_XML, $whitespace) or die "can't write to: $fname_XML";
