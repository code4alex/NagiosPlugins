#!/bin/bash

#set nagios status
STATE_OK=0
STATE_WARNING=1
STATE_CRITICAL=2
STATE_UNKNOWN=3

file='/u01/app/oracle/admin/oa/bdump/alert_oa.log'
#my_date=`date -d "-1 minute" +"%a %b %d %R"`
export LC_ALL=C
my_date=`date -d "-1 minute" +"%a %b %_d %R"`

if [ ! -e ${file} ];then
        echo "${file} not exist!"
        exit ${STATE_UNKNOWN}
fi

info=`mawk "BEGIN{a=0};/${my_date}/{a=NR};a != 0{print}" ${file}|\
grep -E 'ORA-|Error|WARNING|Starting|Shutting'|sort -u`


if [ -z "${info}" ];then
        echo "check oracle bdump ok!"
        exit ${STATE_OK}
else
        error_info=`echo ${info}|awk 'BEGIN{ORS=";"}{print}'`
        echo "Oracle bdump is WARNING! Error info: ${error_info}"
        exit ${STATE_CRITICAL}
fi
