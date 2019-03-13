#!/bin/bash

STATE_OK=0
STATE_WARNING=1
STATE_CRITICAL=2
STATE_UNKNOWN=3

warn="$1"

path=`pwd`
file=`echo $0|sed 's/.//'`
test -z "${warn}" &&\
eval "echo please enter: ${path}${file} 10000;exit ${STATE_UNKNOWN}"

tmp_file="/tmp/mq.stat.$$"
trap "exit 1"           HUP INT PIPE QUIT TERM
trap "test -f ${tmp_file} && rm -f ${tmp_file}"  EXIT

influx -database telegraf -format csv \
-execute 'SELECT mean("messages") FROM "rabbitmq_queue" WHERE time > now() -1m GROUP BY time(10s), "queue", "node" fill(none)'|\
grep -Ev '^name'|\
mawk -F',' -v value=${warn} '$NF>value{print $(NF-3),$(NF-2),$NF}'|\
sort -u|sed 's/"//g'|\
while read node queue num
do
    eval "${node};${queue}"
    echo "${node} ${queue} ${num}"
done > ${tmp_file}

if [ -s "${tmp_file}" ];then
    echo "Check rabbitmq_queue is WARNING!"
    cat ${tmp_file}
    number=`cat ${tmp_file}|mawk '{sum+=$NF}END{print sum}'`
    echo "|num=${number};;;"
    exit ${STATE_WARNING}
else
    echo "Check rabbitmq_queue is OK!|num=0;;;" && exit ${STATE_OK}
fi

exit ${STATE_UNKNOWN}
