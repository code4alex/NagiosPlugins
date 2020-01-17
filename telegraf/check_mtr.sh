#!/bin/bash

ip="$1"

help () {
    echo -en "Usage: $0 ipaddr \nFor example:\t$0 10.0.0.1\n" 1>&2
    exit 1
}

test -z "${ip}" && help

#nagios exit code
STATE_OK=0
STATE_WARNING=1
STATE_CRITICAL=2
STATE_UNKNOWN=3

TEMP="/tmp/check_mtr_temp.$$"

#SET EXIT STATUS AND COMMAND
trap "exit 1"           HUP INT PIPE QUIT TERM
trap "rm -f ${TEMP}"  EXIT

#mtr --report -4 --tcp --no-dns ${ip} |grep -v '???'|awk '/%/{print $2,$3}'|sed 1d > ${TEMP}
mtr --no-dns -4 --report ${ip} |grep -v '???'|awk '/%/{print $2,$3}'|sed 1d > ${TEMP}

test -f ${TEMP} ||\
eval "${TEMP} not found!;exit ${STATE_UNKNOWN}"

hostname=`hostname`
timetamp=`date -d now +"%s%N"`
cat ${TEMP}|sed 's/%//'|\
while read loss_ip loss
do
    loss_int=`echo "${loss}/1"|bc`
    echo "net_mtr,hostname=${hostname},dst_ip=${ip},loss_ip=${loss_ip} loss=${loss_int} ${timetamp}"
done 
#> ${TEMP}
#test -f ${TEMP} && cat ${TEMP}
