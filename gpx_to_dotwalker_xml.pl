#!/usr/bin/perl
#
# by Matija Nalis <mnalis-blind@voyager.hr> GPLv3+ started 2014-07-09
# home at https://github.com/mnalis/gpx_to_dotwalker_xml
#
# command line version
#
# Creates router.XML for Dotwalker from .gpx
# Use extended format routing GPX  from for example http://graphhopper.com/maps/
# Dotwalker is GPS application for blind people; http://www.dotwalker.wz.cz/dotwalker_en.html
#
# requires XML::LibXML perl module ("apt-get install libxml-libxml-perl")
#
# FIXME - move to SAX for less memory usage and faster processing on bigger XMLs?

use strict;
use warnings;
use autodie;
#use diagnostics;

my $DEBUG = 0;
my $whitespace = 0;	# 1/2 for debug, 0 for production (no spaces)

use XML::LibXML;
local $XML::LibXML::setTagCompression = 1;	# As we don't know if Dotwalker supports <Description /> short-empty-tag, use the value we know it supports <Description></Description>
binmode STDOUT, ':utf8';	# our terminal is UTF-8 capable (we hope)

my $VERSION = '0.88';

# returns title and description (as first and second preferred tags)
sub get_title_desc($) {
  my ($point) = @_;
  my $title = '';
  my $desc = '';
  
  # fills first or second reference with next most preferred tag (depending which one is already filled)
  sub try_next($$$$$) {
    my ($ref1, $ref2, $pre, $post, $value) = @_;
    if ($value) {
      $value = "$pre $value" if $pre;
      $value .= $post if ($post);
      if (!$$ref1) {
        $$ref1 = $value;
      } elsif (!$$ref2) {
        $$ref2 = $value;
      } else {
        $$ref2 .= ", $value";
      }
    }
  }
  
  try_next (\$title, \$desc, '', '',  $point->getElementsByTagName('desc')->string_value);
  try_next (\$title, \$desc, '', '', $point->getElementsByTagName('name')->string_value);
  try_next (\$title, \$desc, '', '', $point->getElementsByTagName('cmt')->string_value);
  
  my $ext = ($point->getElementsByTagName('extensions'))[0];	# there should only be one extensions block
  if ($ext) {
    try_next (\$title, \$desc, 'direction', '', $ext->getElementsByTagName('direction')->string_value);
    try_next (\$title, \$desc, 'distance', 'm', int($ext->getElementsByTagName('distance')->string_value));
  }
  
  return ($title, $desc);
}

my $fname_GPX = $ARGV[0];
my $fname_XML = $ARGV[1];

if (!defined ($fname_GPX) or !defined($fname_XML)) {
    print "gpx_to_dotwalker_xml.pl v$VERSION\n";
    print "Usage: $0 <input.GPX> <output.XML>\n\n";
    print "input or/and output file can be '-', signifying stdin/stdout\n";
    print "This program Creates XML for Dotwalker from .GPX\n";
    exit 1;
}

# parse given .gpx
my $gpxdom = XML::LibXML->load_xml (location => $fname_GPX, no_network => 1) or die "ERROR: can't parse $fname_GPX";

# create empty dotwalker .xml
my $xmldom = XML::LibXML::Document->new('1.0', 'utf-8');
$xmldom->setStandalone(1);
my $xmlroot = $xmldom->createElement('Route');


# there are three types of GPX, try them in preference: Route, Waypoints, Track
# see http://en.wikipedia.org/wiki/GPS_Exchange_Format
my @route = $gpxdom->getElementsByTagName('rtept');
if (!@route) { @route = $gpxdom->getElementsByTagName('wpt'); }
if (!@route) { @route = $gpxdom->getElementsByTagName('trkpt'); }


$DEBUG && print "Parsing from GPX $fname_GPX to Dotwalker XML $fname_XML\n\n";
my $count = 1;
foreach my $point (@route) {
  my $lat = $point->getAttribute('lat');
  my $lon = $point->getAttribute('lon');
  my ($title, $desc) = get_title_desc($point);
  
  if (!$title) { $title = "Point $count" }
  $count++;
  
  $DEBUG && print "parsing POINT: lat=$lat, lon=$lon title=$title desc=$desc\n";

  my $newPoint = $xmldom->createElement('Point');
  $newPoint->appendTextChild('Title', $title);
  $newPoint->appendTextChild('Lat', $lat);
  $newPoint->appendTextChild('Lng', $lon);
  $newPoint->appendTextChild('Description', $desc);
  $xmlroot->appendChild($newPoint);
}


$xmldom->setDocumentElement($xmlroot);
$xmldom->toFile($fname_XML, $whitespace) or die "ERROR: can't write to: $fname_XML: $!";
