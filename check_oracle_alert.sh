#!/bin/bash

#set nagios status
STATE_OK=0
STATE_WARNING=1
STATE_CRITICAL=2
STATE_UNKNOWN=3

usage () {
        echo -en "USAGE: $0 /opt/oracle/logs/alert.log\n" 1>&2
        exit ${STATE_WARNING}
}

file="$1"

export LC_ALL=C
my_date=`date -d "-1 minute" +"%a %b %d %R"`

if [ ! -e ${file} ];then
        echo "${file} not exist!"
	usage
#        exit ${STATE_UNKNOWN}
fi

info=`tail -n 2000 ${file}|mawk "BEGIN{a=0};/${my_date}/{a=NR};a != 0{print}"|\
grep -E 'ORA-|Error|WARNING|Starting|Shutting'|grep -v 'process VKRM'|sort -u`


if [ -z "${info}" ];then
        echo "check oracle bdump ok!"
        exit ${STATE_OK}
else
        error_info=`echo ${info}|awk 'BEGIN{ORS=";"}{print}'`
        echo "Oracle bdump is WARNING! Error info: ${error_info}"
        exit ${STATE_CRITICAL}
fi
