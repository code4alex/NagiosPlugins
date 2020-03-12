#!/bin/bash

#nagios exit code
STATE_OK=0
STATE_WARNING=1
STATE_CRITICAL=2
STATE_UNKNOWN=3

test -f /usr/bin/docker ||\
eval "/usr/bin/docker not found!;exit ${STATE_UNKNOWN}"

tmp="/tmp/check_docker.$$"

trap "exit 1"           HUP INT PIPE QUIT TERM
trap "test -f ${tmp} && rm -f ${tmp}"  EXIT

sudo docker service ls > ${tmp}

total=`wc -l ${tmp}|awk '{print $1}'`
error_num=`grep ' 1/' ${tmp}|wc -l`

if [ "$error_num" == '0' ];then
    echo "Docker Service is OK! Total:${total}|error=0;;;"
    exit ${STATE_OK}
else
    echo "Docker Service is WARNING! Error/Total: ${error_num}/${total}"
    echo -en "REPLICAS\tNAME\n"
    grep ' 1/' ${tmp}|awk 'BEGIN{OFS="\t"}{print $4,$2}' 
    echo "|error=${error_num};;;"
    exit ${STATE_WARNING}
fi
