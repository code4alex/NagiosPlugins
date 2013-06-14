#!/bin/bash

#set nagios status
STATE_OK=0
STATE_WARNING=1
STATE_CRITICAL=2
STATE_UNKNOWN=3

usage (){
        echo -en "Usage: $0 -s [service] -p [port]\nFor example:\t$0 -s squid -p 3128\n" 1>&2
        exit ${STATE_WARNING}
}

while getopts s:p: opt
do
        case "$opt" in
        s) service_name="$OPTARG";;
        p) port="$OPTARG";;
        *) usage;;
        esac
done

shift $[ $OPTIND - 1 ]

if [ -z "${service_name}" -o -z "${port}" ];then
        usage
fi

active_num=`ipvsadm -ln|awk '$1~/->/ && $2~/:'"${port}"'/{sum+=$(NF-1)}END{print sum}'`

echo "${active_num}"|grep -E '^[0-9]+$' >/dev/null 2>&1 || eval "echo Active number is error!;exit ${STATE_UNKNOWN}"

if [ ${active_num} -gt 0 ];then
        echo "${service_name} is OK! active_num = ${active_num}."
        exit ${STATE_OK}
else
        echo "${service_name} is Warning! active_num = ${active_num}."
        exit ${STATE_WARNING}
fi
