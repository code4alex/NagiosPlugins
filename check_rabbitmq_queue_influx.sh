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
-execute 'SELECT mean("messages") FROM "rabbitmq_queue" WHERE time > now() -1m GROUP BY time(30s), "queue", "node" fill(none)'|\
grep -Ev '^name'|\
mawk -F',' '$NF>0{print $(NF-3),$(NF-2),$NF}'|\
sort -u|sed 's/"//g'|\
while read node queue num
do
    eval "${node};${queue}"
    echo "${node} ${queue} ${num}"
done > ${tmp_file}

[ ! -s "${tmp_file}" ] && echo "Check rabbitmq_queue is OK!|num=0;;;" && exit ${STATE_OK}

number=`mawk '{stats[$1" "$2]+=$3;count[$1" "$2]+=1}END{for (stat in stats) {sum+=stats[stat]/count[stat]};print sum}' ${tmp_file}|xargs -r -i echo "{}/1"|bc`
#echo ${number}

if [ ${number} -ge ${warn} ];then
    echo "Check rabbitmq_queue is WARNING!"
    mawk '{stats[$1" "$2]+=$3;count[$1" "$2]+=1}END{for (stat in stats) {print stat,stats[stat]/count[stat]}}' ${tmp_file}|\
    while read node queue value
    do
        num_int=`echo ${value}/1|bc`
        echo "$node $queue $num_int"
    done|sort -nrk3
    echo "|num=${number};;;"
    exit ${STATE_WARNING}
else
    echo "Check rabbitmq_queue is OK!${number}/min|num=${number};;;" && exit ${STATE_OK}
fi

exit ${STATE_UNKNOWN}
