#!/bin/bash

#set nagios status
STATE_OK=0
STATE_WARNING=1
STATE_CRITICAL=2
STATE_UNKNOWN=3

usage () {
        echo -en "USAGE: $0 -d coretemp-isa-0000 -c 35\n" 1>&2
        exit ${STATE_WARNING}
}

check_para () {
local para="$1"
echo "${para}"|\
grep -E '^[0-9]+$' >/dev/null 2>&1 ||\
eval "echo Error parameters: ${para} . Please enter numbers. 1>&2;exit ${STATE_WARNING}"
}

while getopts d:c: opt
do
        case "$opt" in
        d) 
                sensors "$OPTARG" >/dev/null || exit ${STATE_UNKNOWN}
                dev="$OPTARG"
        ;;
        c) 
                check_para "$OPTARG"
                critical="$OPTARG"
        ;;
        *) usage;;
        esac
done

shift $[ $OPTIND - 1 ]

if [ $# -gt 0 -o -z "${dev}" -o -z "${critical}" ];then
        usage
fi

info=`sensors ${dev}|grep -E '^Core'|\
awk -F'°' '{print $1}'|sed -r 's/\+//g;s/[ ]+/ /g'|\
awk -F':' -v cri="${critical}" '{temp=$2};temp>cri{ORS=";";print $1":"$2"°C"}'`

if [ -z "${info}" ];then
        echo "OK - Sensors: ${dev}|WARN=0;;;"
        exit ${STATE_OK}
else
        echo "CRITICA - ${info}|WARN=1;;;"
        exit ${STATE_CRITICA}
fi
