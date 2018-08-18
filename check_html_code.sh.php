<?php
#放到/omd/sites/you-site/etc/pnp4nagios/templates/ 下

$opt[1] = "--vertical-label 'Number' -u 10 -X0 --title \"HTML stats on $hostname\" ";

$stats = array(
  array(1,  "Code_200", "", "#00FF00", ""),
  array(2,  "Code_400", "  ", "#E2F886", ""),
  array(3,  "Code_403", "  ", "#F7FE2E", ""),
  array(4,  "Code_404", "     ", "#FF0000", "\\n"),
  array(5,  "Code_499", " ", "#FF9900", ""),
  array(6,  "Code_500", "    ", "#58FAD0", ""),
  array(7,  "Code_501", "   ", "#6633FF", ""),
  array(8,  "Code_502", "  ", "#000066", "")
);

$def[1] = "";

foreach ($stats as $entry) {
   list($i, $stat, $spaces, $color, $nl) = $entry;
   $def[1] .= "DEF:$stat=$RRDFILE[$i]:$DS[$i]:MAX ";
   $def[1] .= "AREA:$stat$color:\"$stat\":STACK ";
   $def[1] .= "GPRINT:$stat:LAST:\"$spaces%3.0lf$nl\" ";
}
