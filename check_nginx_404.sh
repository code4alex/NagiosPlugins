#!/bin/bash

log="$1"

#set nagios status
STATE_OK=0
STATE_WARNING=1
STATE_CRITICAL=2
STATE_UNKNOWN=3

tmp_file="/tmp/nginx.log.$$"

trap "exit 1"           HUP INT PIPE QUIT TERM
trap "test -f ${tmp_file} && rm -f ${tmp_file}"  EXIT

test -f ${log} ||\
eval "echo ${log} not found!;exit ${STATE_UNKNOWN}"

time_str=`date -d -1min +":%T"|sed 's/..$//'`

tail -n20000 ${log}|grep "${time_str}" |\
grep -v 'varnish.html'|\
grep '\" 404 '|awk '{print $7}' > ${tmp_file}

stat_404_num=`cat ${tmp_file}|wc -l`

if [ "${stat_404_num}" == '0' ];then
        echo "OK - 404 status is ${stat_404_num}|stat_404=${stat_404_num};;;"
        exit ${STATE_OK}
else
        echo "WARNING - 404 status is ${stat_404_num}.less ${log}|stat_404=${stat_404_num};;;"
        exit ${STATE_WARNING}
fi

exit ${STATE_UNKNOWN}
