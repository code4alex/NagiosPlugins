#!/bin/bash

dev="$1"
/bin/ip addr show dev $dev >/dev/null || exit 1

server=`/bin/ip addr show dev ${dev}|grep -oP '\d{1,3}(\.\d{1,3}){3}'|grep -Ev '^127|255$'|head -n1`
#echo $server
hostname=`hostname`

tmp="/tmp/net_count.$$"
#SET EXIT STATUS AND COMMAND
trap "exit 1"           HUP INT PIPE QUIT TERM
trap "test -f ${tmp} && rm -f ${tmp}"  EXIT

#ss -atn4
timetamp=`date -d now +"%s%N"`
ss -4tan|grep -Ev '^State|^LISTEN'|awk '{print $NF,$(NF-1)}'|awk -F':' '{print $1,$NF}' > ${tmp}
ss -4tnl|awk '/^LISTEN/{print $4}'|awk -F':' '{print $2}'|\
xargs -r -i grep -E ' {}$' ${tmp}|sort|uniq -c|\
awk -v hostname="$hostname" -v timetamp="$timetamp" '{print "src_ip_port,hostname="hostname",src_ip="$2",port="$NF" count="$1" "timetamp}'
