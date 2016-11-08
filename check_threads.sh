#!/bin/bash

#nagios exit code
STATE_OK=0
STATE_WARNING=1
STATE_CRITICAL=2
STATE_UNKNOWN=3

#help
help () {
    local command=`basename $0`
        echo "NAME
    ${command} -- check threads
SYNOPSIS
    ${command} [OPTION]
DESCRIPTION
    -w warning
USAGE:
Check threads:
    $0 -w 1024" 1>&2
        exit ${STATE_WARNING}
}

check_num () {
    local num_str="$1"
    echo ${num_str}|grep -E '^[0-9]+$' >/dev/null 2>&1 || local stat='not a positive integers!'
    if [ "${stat}" = 'not a positive integers!' ];then
        echo "${num_str} ${stat}" 1>&2
        exit ${STATE_WARNING}
    else
        local num_int=`echo ${num_str}*1|bc`
        if [ ${num_int} -lt 0 ];then
            echo "${num_int} must be greater than 0!" 1>&2
            exit ${STATE_WARNING}
        fi
    fi
}

#input
while getopts w: opt
do
        case "$opt" in
        w)
            warning=$OPTARG
            check_num "${warning}"
        ;;
        *) help;;
        esac
done
shift $[ $OPTIND - 1 ]

[ $# -gt 0 -o -z "${warning}" ] && help

message () {
    local stat="$1"
    local msg="$2"
    echo "System threads is ${stat} - ${msg}|threads=${threads};${warning};${critical};${min};${max}"
}

threads=`ps -eLf|grep -v UID|wc -l`

info=`ps -eLf |awk '{sum[$1]++}END{for (i in sum) print i,sum[i]}'|grep -v UID|awk -v num=${warning} 'BEGIN{ORS=";"}$2>=num{print}'`

if [ -z "${info}" ];then
        message 'OK' "Threads: ${threads}"
        exit ${STATE_OK}
else
        message 'WARNING' "${info} (>${warning}!)"
        exit ${STATE_WARNING}
fi

exit ${STATE_UNKNOWN}
