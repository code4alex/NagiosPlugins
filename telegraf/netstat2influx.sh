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
ss -atn4|grep -Ev '^LISTEN|^State'|awk '{print $4,$1}' > ${tmp}
ss -4tnl |awk '{print $4}'|grep -oP ':\d+'|\
xargs -r -i grep '{} ' ${tmp}|awk -F':' '{print $NF}'|sort|uniq -c|\
awk -v ip="$server" -v hostname="$hostname" -v timetamp="$timetamp" '{print "netstat2json,hostname="hostname",ip="ip",status="$3",port="$2" count="$1" "timetamp}'
#json
#awk -v ip="$server" '{print "{\"ip\":\""ip"\",\"name\":\"netstat2json\",\"status\":""\""$3"\",\"port\":\""$2"\",\"count\":"$1"}"}'
