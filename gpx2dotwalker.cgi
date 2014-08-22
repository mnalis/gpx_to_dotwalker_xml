#!/usr/bin/perl
#
# by Matija Nalis <mnalis-blind@voyager.hr> GPLv3+ started 2014-07-09
# home at https://github.com/mnalis/gpx_to_dotwalker_xml
#
# web server .cgi version
#
# requires gpx_to_dotwalker_xml.pl and its dependencies (and CGI perl module)

# FIXME convert standalone perl converter so it can be also be used as module (to avoid ugly exec and handle errors)
# FIXME add error handling (if not GPX file, or if no waypoints extracted)
# FIXME add gpsbabel support for more file types (as needed)

use warnings;
use strict;
use autodie qw(:default exec);
#use diagnostics;

my $g2x_path = './gpx_to_dotwalker_xml.pl';	# make this correct path if not in the same directory
my $l2g_path = './loadstone_to_gpx.pl';
my $PERL = '/usr/bin/perl';

use CGI qw(:standard);
use CGI::Carp qw(fatalsToBrowser);

$| = 1;

die "can't find $g2x_path" unless -r $g2x_path;
die "can't find $l2g_path" unless -r $l2g_path;


# detect file format: return gpx or lsdb or unknown.
sub detect_format($)
{
	my ($filename) = @_;
	open my $fd, '<', $filename;
	my $line = <$fd>;
	if ($line =~ /xml/i) {
		return 'gpx';	# FIXME: assume XML file is gpx. we should be smarter...
	} elsif ($line =~ /lsdb/i) {
		return 'lsdb';
	} else {
		return "UNKNOWN - first line is: $line";
	}
}

# here goes main
my $VERSION;
{
open my $help_fd, '-|', "$PERL $g2x_path";
$VERSION = <$help_fd>; 
chomp $VERSION;
$VERSION =~ s/^.* (v.+)$/$1/;
}

my $AUTHOR = 'Written by ' . a({-href => 'mailto:mnalis-blind@voyager.hr'}, 'Matija Nalis') . ' of ' . a({-href => 'http://biciklijade.com/'}, 'biciklijade.com') . ' fame (not affiliated with Dotwalker).';
my $SOURCE = 'Source code ' . a({-href => 'https://github.com/mnalis/gpx_to_dotwalker_xml'}, 'released') . ' under GPLv3 or higher.';
my $CREDITS = 'Kindly hosted by ' . a({-href => 'http://voyager.hr/'}, 'Voyager.hr');	# change this when you host elsewhere

my $gpx_fd = upload('gpx_file');

if (defined $gpx_fd) {			# gpx file uploaded, process it
	my $gpx_remotefilename = param('gpx_file');

	my $gpx_localfilename = $gpx_remotefilename; $gpx_localfilename =~ s{^(?:.*[/\\])?(.+?)(?:\.gpx|\.xml|\.txt|\.csv)$}{${1}_dotwalker_route.xml}i;

	my $gpx_tmpfilename = tmpFileName($gpx_remotefilename);
	my $format = detect_format($gpx_tmpfilename);

	if ($format eq 'gpx') {
		print header (-type => 'application/xml', -charset => 'utf-8', -Content_Disposition => qq{attachment; filename="$gpx_localfilename"});
		exec ($PERL, $g2x_path, $gpx_tmpfilename, '-');
	} elsif ($format eq 'lsdb') {
		print header (-type => 'application/xml', -charset => 'utf-8', -Content_Disposition => qq{attachment; filename="$gpx_localfilename"});
		exec "$l2g_path $gpx_tmpfilename - | $g2x_path - -"; # FIXME: exec via perl? FIXME: yeah, single argument exec(), no taint mode... should fix that ASAP. see above about doing it via function calls...
	} else {
		die "Unknown file format: $format";
	}
	die "should never reach here; did $g2x_path or $l2g_path fail? $?";
} else {				# no params, show form
	print header (-charset => 'utf-8'),
	start_html (-title => 'GPX to Dotwalker XML converter'),
	h1("GPX/Loadstone to Dotwalker XML converter $VERSION" ),
	'Input file should be one of:',
	ul(
	li('Loadstone export .TXT file'),
	li('.GPX in extended format with descriptions, like the one from ', a({-href => 'http://graphhopper.com/maps/'}, 'GraphHopper.com')),
	),
	'Output will be routing .XML file for Dotwalker Android GPS application (you must save it in Dotwalker as "route.xml")',
	start_form,
	h2('Select GPX or Loadstone file'),
	filefield (-name => 'gpx_file'),
	submit (-label => 'Upload'),
	end_form,
	p($AUTHOR . br . $SOURCE . br . $CREDITS),
	end_html;
}

