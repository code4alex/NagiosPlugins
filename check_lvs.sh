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

tmp_file="/tmp/ipvsadm.info"
test -f ${tmp_file} || eval "echo ${tmp_file} not found!;exit ${STATE_WARNING}"

#active_num=`ipvsadm -ln|awk '$1~/->/ && $2~/:'"${port}"'/{sum+=$(NF-1)}END{print sum}'`
active_num=`awk '$1~/->/ && $2~/:'"${port}"'/{sum+=$(NF-1)}END{print sum}' ${tmp_file}`

echo "${active_num}"|grep -E '^[0-9]+$' >/dev/null 2>&1 ||\
eval "echo active_num is not a number! Please type sh -x $0 to debug!;exit ${STATE_UNKNOWN}"

message () {
local stat="$1"
#set pnp4nagios value
local min=0
local max=1000
echo "${service_name} is ${stat}! active_num = ${active_num}| active_num=${active_num};${warning};${critical};${min};${max}"
}

if [ ${active_num} -gt 0 ];then
        message "OK" && exit ${STATE_OK}
else
        message "Warning" && exit ${STATE_WARNING}
fi
