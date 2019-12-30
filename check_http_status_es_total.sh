#!/bin/bash

STATE_OK=0
STATE_WARNING=1
STATE_CRITICAL=2
STATE_UNKNOWN=3

index="$1"
#percent_warning="$2"
http_status="$2"
streams=${index}
#test -z ${percent_warning} &&\
#eval "echo ${percent_warning} is null!;exit ${STATE_UNKNOWN}"
which bc >/dev/null 2>&1 ||\
eval "echo bc not fonud!;exit ${STATE_UNKNOWN}"

number=`/usr/local/nagios-plugins/check_http_status_es_total.py "${index}" "${http_status}"`

echo ${number}|grep -E '[0-9]+' >/dev/null 2>&1 || graylog_return='fail'
[ "${graylog_return}" = 'fail' ] && echo "graylog query is ${graylog_return}!" && exit ${STATE_UNKNOWN}

message () {
local stat="$1"
    echo "website http status is $stat! QPS:${web_qps}/sec now: ${web_qps}/sec|count=$number;;;qps=${web_qps};;;"
}

web_qps=`echo ${number}/60|bc`

message "OK" && exit ${STATE_OK}
