#!/usr/bin/perl
#
# by Matija Nalis <mnalis-blind@voyager.hr> GPLv3+ started 2014-07-09
# home at https://github.com/mnalis/gpx_to_dotwalker_xml
#
# Creates XML for Dotwalker (GPS application for blind people) from .gpx
# Use extended format routing GPX  from for example http://graphhopper.com/maps/
#
# FIXME - required perl modules and build instructions
# FIXME - do a web version

use strict;
use warnings;
use autodie;
use diagnostics;

my $DEBUG = 1;
binmode STDOUT, ':utf8';	# our terminal is UTF-8 capable (we hope)

use XML::LibXML;
my $VERSION = '0.2';

my $fname_GPX = $ARGV[0];
my $fname_XML = $ARGV[1];

if (!defined ($fname_GPX) or !defined($fname_XML)) {
    print "gpx_to_dotwalker_xml.pl v$VERSION\n";
    print "Usage: $0 <input.GPX> <output.XML>\n\n";
    print "This program Creates XML for Dotwalker from .GPX\n";
    exit 1;
}

die "source GPX file $fname_GPX is not readable, aborting" unless -r "$fname_GPX";
die "destination XML file $fname_XML already exists, aborting" if -e "$fname_XML";

my $parser = XML::LibXML->new();
my $gpxdom = $parser->parse_file($fname_GPX);
my @rte = $gpxdom->getElementsByTagName('rtept');


foreach my $rtept (@rte) {
  use Data::Dumper;
  my $lat = $rtept->getAttribute('lat');
  my $lon = $rtept->getAttribute('lon');
  my $desc = $rtept->getElementsByTagName('desc')->string_value;
  
  $DEBUG && print "parsing RTEPT: lat=$lat, lon=$lon desc=$desc\n";
}
