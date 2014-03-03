#!/bin/bash

user=`whoami`
test -d /tmp/ || exit 1
/usr/sbin/lsof -u ${user} 2>/dev/null|\
awk 'BEGIN{OFS=": ";ORS=";"}NR>1{items[$1]++;sum++}END{print "Total",sum;for (item in items){print item,items[item]}}' > /tmp/lsof.${user}
