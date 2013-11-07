#!/bin/bash

#set nagios status
STATE_OK=0
STATE_WARNING=1
STATE_CRITICAL=2
STATE_UNKNOWN=3

file='/u01/app/oracle/product/10.2.0/db_1/network/log/listener.log'
my_date=`date -d "-1 minute" +"%d-%b-%Y %R"`

if [ ! -e ${file} ];then
        echo "${file} not exist!"
        exit ${STATE_UNKNOWN}
fi

info=`mawk "BEGIN{IGNORECASE=1;a=0};/${my_date}/{a=NR};a != 0{print}" ${file}|\
grep -E 'TNS-'|sort -u`

if [ -z "${info}" ];then
        echo "check oracle listener ok!"
        exit ${STATE_OK}
else
        error_info=`echo ${info}|awk 'BEGIN{ORS=";"}{print}'`
        echo "Oracle listener is WARNING! Error info: ${error_info}"
        exit ${STATE_CRITICAL}
fi
