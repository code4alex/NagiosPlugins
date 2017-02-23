#!/bin/bash

STATE_OK=0
STATE_WARNING=1
STATE_CRITICAL=2
STATE_UNKNOWN=3

test -f /home/oracle/.bash_profile &&\
source /home/oracle/.bash_profile

cmd="$1"
#cmd='/u01/app/ogg/ggsci'
test -x ${cmd} ||\
eval "echo ${cmd} not found!;exit ${STATE_UNKNOWN}"

echo "info all"|${cmd} >/dev/null 2>&1 ||\
eval "echo Check OGG replicat error!;exit ${STATE_UNKNOWN}"

info=`echo "info all"|${cmd}|grep REPLICAT`

num=`echo ${info}|grep -oP '00:0[0-9]:\d{2}'|wc -l`

info=`echo ${info}|sed -r 's/[ ]+/ /g'`
if [ ${num} -ge 2 ];then
    echo "OGG replicat is OK! ${info}|timeout=0;;;"
    exit ${STATE_OK}
else
    echo "OGG replicat is WARNING! ${info}|timeout=1;;;"
    exit ${STATE_WARNING}
fi

exit ${STATE_UNKNOWN}
