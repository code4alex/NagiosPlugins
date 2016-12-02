#!/bin/bash

STATE_OK=0
STATE_WARNING=1
STATE_CRITICAL=2
STATE_UNKNOWN=3

log_file="$1"

test -f ${log_file} || \
eval "echo ${log_file} not found!;exit ${STATE_UNKNOWN}"

time_now=`date -d -1min +"%F %T"|sed -r 's/..$//'`

info=`grep "${time_now}" ${log_file} |grep 'ERROR'|grep 'OGG-'|head -n1|grep -oP '^.{19,100}'|head -n1`


if [ -z "${info}" ];then
        echo "check OGG is OK!|error=0;;;;" && exit ${STATE_OK}
else
        echo "check OGG is WARNING!|error=1;;;;" && exit ${STATE_WARNING}
fi

exit ${STATE_UNKNOWN}
