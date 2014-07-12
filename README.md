gpx_to_dotwalker_xml
====================

( home is currently at https://github.com/mnalis/gpx_to_dotwalker_xml )

Creates XML for Dotwalker (GPS application for blind people) from .gpx
You will need perl and XML::LibXML module.

Instructions:
1) create .gpx routing file in extended format (or you'll miss turn directions)
   for example from: http://graphhopper.com/maps/

2) run "./gpx_to_dotwalker_xml.pl GrasHopper.gpx output.xml"

3) insert output.xml to Dotwalker 


There is also web CGI version gpx2dotwalker.cgi.

see http://mnalis.com/blind/g2dot/gpx2dotwalker.cgi for online converter, or set up your own.

Contact Matija Nalis <mnalis-blind@voyager.hr> for ideas for improvement.
