<?php
#
# Copyright (c) 2006-2010 Joerg Linge (http://www.pnp4nagios.org)
# Plugin: check_gc_count.php
#
#
$ds_name[1] = "Check GC Count";
$opt[1]  = "--lower-limit 0 --vertical-label \"Check GC Count\"  --title \"Check GC Count\" ";
$def[1]  =  rrd::def("var1", $RRDFILE[1], $DS[1], "AVERAGE") ;
$def[1] .=  rrd::gradient("var1", "ff5c00", "ffdc00", "Check GC Count", 10) ;
$def[1] .=  rrd::gprint("var1", array("LAST", "MAX", "AVERAGE"), "%.0lf $UNIT[1]") ;
$def[1] .=  rrd::line1("var1", "#000000") ;

if($WARN[1] != ""){
        if($UNIT[1] == "%%"){ $UNIT[1] = "%"; };
        $def[1] .= rrd::hrule($WARN[1], "#FFFF00", "Warning  ".$WARN[1].$UNIT[1]."\\n");
}
if($CRIT[1] != ""){
        if($UNIT[1] == "%%"){ $UNIT[1] = "%"; };
        $def[1] .= rrd::hrule($CRIT[1], "#FF0000", "Critical ".$CRIT[1].$UNIT[1]."\\n");
}

?>
