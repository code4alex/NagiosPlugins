#!/bin/bash

dev_name="$1"
test -z ${dev_name} &&\
eval "echo dev_name is null!;exit 1"

hostname=`hostname`
ip=`/sbin/ip addr list|grep -E "${dev_name}$"|grep -oP '\d{1,3}(\.\d{1,3}){3}'|grep -Ev '^127|255$'|head -n1`
timetamp=`date -d now +"%s%N"`

netstat -ant|awk '{print $NF}'|sed '1,2d'|sort|uniq -c|sort -nrk1|\
awk -v hostname="${hostname}" -v ip="${ip}" -v timetamp="${timetamp}" \
'{print "tcp_stat,host="hostname",server="ip",status="$2" count="$1" "timetamp}'
