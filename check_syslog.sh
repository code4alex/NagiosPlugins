#!/bin/bash

#nagios exit code
STATE_OK=0
STATE_WARNING=1
STATE_CRITICAL=2
STATE_UNKNOWN=3

help () {
        local command=`basename $0`
        echo "NAME
        ${command} -- Check Syslog
SYNOPSIS
        ${command} [OPTION]
DESCRIPTION
        -f syslog
        -s string
USAGE:
        $0 -f /var/log/messages -s Standby" 1>&2
        exit ${STATE_WARNING}
}

#input
while getopts f:s:d: opt
do
        case "$opt" in
        f)
                syslog=$OPTARG 
                test -f "${syslog}" ||\
                eval 'echo '${syslog}' not found! 1>&2;exit '${STATE_WARNING}''
        ;;
        s)
                search_str=$OPTARG
        ;;
        d)
                search_type=$OPTARG
        ;;
        *)      help;;
        esac
done
shift $[ $OPTIND - 1 ]

[ $# -gt 0 -o -z "${syslog}" -o -z "${search_str}" ] && help

time_now=`date -d "-1 min" +"%FT%T"|sed -r 's/..$//'`
error_num=`tail -n 5000 ${syslog}|grep -E "^${time_now}"|grep "${search_str}"|grep "${search_type}"|wc -l`

if [ ${error_num} -eq 0 ];then
        echo "Check SYSLOG is OK"
        exit ${STATE_OK}
else
        echo "Check SYSLOG is CRITICAL! \"${search_str}\" is match! ${error_num}/min" 1>&2
        exit ${STATE_CRITICAL}
fi
