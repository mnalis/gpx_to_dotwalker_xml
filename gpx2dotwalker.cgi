#!/usr/bin/perl
#
# by Matija Nalis <mnalis-blind@voyager.hr> GPLv3+ started 2014-07-09
# home at https://github.com/mnalis/gpx_to_dotwalker_xml
#
# web server .cgi version
#
# requires gpx_to_dotwalker_xml.pl and its dependencies (and CGI perl module)

use warnings;
use strict;
use autodie qw(:default exec);
#use diagnostics;

my $g2x_path = './gpx_to_dotwalker_xml.pl';	# make this correct path if not in the same directory
my $PERL = '/usr/bin/perl';

use CGI qw(:standard);
use CGI::Carp qw(fatalsToBrowser);

$| = 1;

die "can't find $g2x_path" unless -r $g2x_path;

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

	my $gpx_localfilename = $gpx_remotefilename; $gpx_localfilename =~ s{^(?:.*[/\\])?(.+?)(?:\.gpx|\.xml)$}{${1}_dotwalker_route.xml};
#	print header (-type => 'application/octet-stream');
#	print header (-type => 'application/xml', -charset => 'utf-8');
	print header (-type => 'application/xml', -charset => 'utf-8', -Content_Disposition => qq{attachment; filename="$gpx_localfilename"});

	my $gpx_tmpfilename = tmpFileName($gpx_remotefilename);
	exec ($PERL, $g2x_path, $gpx_tmpfilename, '-'); 
	die "should never reach here; did $g2x_path fail? $?";
} else {				# no params, show form
	print header (-charset => 'utf-8'),
	start_html (-title => 'GPX to Dotwalker XML converter'),
	h1("GPX to Dotwalker XML converter $VERSION" ),
	'Input .GPX file should be in routing extended format with descriptions, like the one from ', a({-href => 'http://graphhopper.com/maps/'}, 'GraphHopper.com'),
	br,
	'Output will be routing .XML file for Dotwalker Android GPS application (you must save it in Dotwalker as "route.xml")',
	start_form,
	'Select GPX file',
	filefield (-name => 'gpx_file'),
	submit (-label => 'Upload GPX'),
	end_form,
	p($AUTHOR . br . $SOURCE . br . $CREDITS),
	end_html;
}

