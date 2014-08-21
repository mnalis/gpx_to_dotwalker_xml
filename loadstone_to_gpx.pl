#!/usr/bin/perl
#
# by Matija Nalis <mnalis-blind@voyager.hr> GPLv3+ started 2014-08-21
# home at https://github.com/mnalis/gpx_to_dotwalker_xml
#
# command line version
#
# Creates XML extended format routing GPX  from Loadstone export text file "#!lsdb"
# Loadstone is GPS application for blind people; http://www.loadstone-gps.com/
#
# requires Geo::Gpx perl module ("apt-get install libgeo-gpx-perl" on Jessie or higher)
# and Text::CSV ("apt-get install libtext-csv-perl")
#
# FIXME: make gpx route object instead? but needs rewriting, can't add one by one rtePt as I can wPt with Geo::GPX?

use strict;
use warnings;
use autodie;
#use diagnostics;

my $DEBUG = 0;

use Geo::Gpx;
use Text::CSV;
binmode STDOUT, ':utf8';	# our terminal is UTF-8 capable (we hope)

my $VERSION = '0.1';

my $fname_LSDB = $ARGV[0];
my $fname_GPX = $ARGV[1];
my %extra;
my $row;

# adds tag to GPX if it exists in source
sub add_if_exists($$$$) 
{
  my ($src, $dst, $prefix, $postfix) = @_;
  if (defined $row->{$src}) {
    $extra{$dst} .=  $prefix . $row->{$src} . $postfix;
    print "  adding extra attribute $src/$dst => " . $prefix . $row->{$src} . $postfix . "\n" if $DEBUG > 2;
  }
}  

if (!defined ($fname_LSDB) or !defined($fname_GPX)) {
    print "loadstone_to_gpx.pl v$VERSION\n";
    print "Usage: $0 <loadstone_input.TXT> <output.GPX>\n\n";
    print "input or/and output file can be '-', signifying stdin/stdout\n";
    print "This program creates standard routing .GPX from Loadstone 'lsdb' export text file\n";
    exit 1;
}

# parse given Loadstone input file
open my $lsdb_fd, "< $fname_LSDB";	# need 2-arg open so '-' will work as alias for stdin
binmode $lsdb_fd, ':utf8';		# input file is UTF-8 capable (we hope)

my $lsdb_fmt = <$lsdb_fd>; 
$lsdb_fmt =~ s/\r?\n$//;	# instead of chomp to handle both \n and \r\n
if ($lsdb_fmt ne '#!lsdb') {
  die "Invalid input format (not Loadstone '#!lsdb' .txt file) -- first line is >$lsdb_fmt<\n";
}

my $lsdb_type = <$lsdb_fd>;
if ($lsdb_type !~ /table,point/) {
  die "Invalid input format (not Loadstone 'table,point' .txt file) -- second line is $lsdb_type\n";
}

my $csv = Text::CSV->new ({ auto_diag => 2, binary=>1 });	# die on errors with diagnostics. need binary for UTF-8
my $head_ref = $csv->getline ($lsdb_fd);	# read all field names, should be: "name,latitude,longitude,accuracy,satellites,priority,userid,id"
$csv->column_names(@$head_ref);	

# create empty .gpx
my $gpx = Geo::Gpx->new();
$gpx->link({ href => 'https://github.com/mnalis/gpx_to_dotwalker_xml', text => "Converted by loadstone_to_gpx.pl v$VERSION" });
$gpx->name($fname_LSDB) if $fname_LSDB ne '-';

$DEBUG && print "Parsing from Loadstone $fname_LSDB to GPX $fname_GPX\n\n";
my $count = 1;

# add all waypoints one by one
while ($row = $csv->getline_hr ($lsdb_fd)) {
  my $name = $row->{name};
  if (!$name) { $name = "Point $count" }
  $count++;

  my $lat=$row->{latitude} / 10000000;
  my $lon=$row->{longitude} / 10000000;
  if (!$lat or !$lon)  {
    $DEBUG && print "skipping missing lat/lon for $name";
    next;
  };	
  
  print "parsing $lat,$lon\t$name\n" if $DEBUG > 1;
  
  %extra = ();
  add_if_exists ('satellites', 'sat', '', '');
  add_if_exists ('accuracy', 'pdop', '', '');	# FIXME: well, it probably isn't the same
  
  # FIXME - remote last space in 'cmt' after they are all finished
  add_if_exists ('priority', 'cmt', 'priority=', ' ');
  add_if_exists ('id', 'cmt', 'id=', ' ');
  add_if_exists ('userid', 'cmt', 'userid=', ' ');
  add_if_exists ('test', 'cmt', 'test=', ' ');	# this does not really exist, just for test
  
  
  $gpx->add_waypoint ({
    lat => $lat,
    lon => $lon,
    name => $name,
    %extra
  });
}

# write output GPX 1.1 file
my $xml = $gpx->xml( '1.1' );
die "refusing to overwrite $fname_GPX" if -e $fname_GPX;
open my $gpx_fd, "> $fname_GPX";	# need 2-arg open so '-' will work as alias for stdout
print $gpx_fd $xml or die "can't append to $fname_GPX: $!";
close $gpx_fd;
