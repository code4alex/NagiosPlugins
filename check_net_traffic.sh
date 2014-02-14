#!/bin/bash

#set nagios status
STATE_OK=0
STATE_WARNING=1
STATE_CRITICAL=2
STATE_UNKNOWN=3

usage (){
        echo -en "Usage: $0 -d [ eth|bond ]\nFor example:\t$0 -d bond0\n" 1>&2
        exit ${STATE_WARNING}
}

while getopts d: opt
do
        case "$opt" in
        d) dev_id="$OPTARG";;
        *) usage;;
        esac
done

shift $[ $OPTIND - 1 ]

if [ -z "${dev_id}" ];then
        usage
fi

source_file='/proc/net/dev'
if [ ! -f "${source_file}" ];then
		echo "${source_file} not not exsit!" 1>&2
		exit ${STATE_WARNING}
fi

grep "${dev_id}" ${source_file} >/dev/null 2>&1 || dev_stat='not found'
if [ "${dev_stat}" = 'not found' ];then
		echo "${dev_id} ${dev_stat}!" 1>&2
		usage
fi

time_now=`date -d now +"%F %T"`
mark="/usr/local/nagios/libexec/net_traffic.${dev_id}"
info=`awk -F':|[ ]+' -v date="${time_now}"  '/'${dev_id}'/{print "${TIME}="date,"${RX}="$3,"${TX}="$11",${DEV}='${dev_id}'"}' "${source_file}"`

if [ ! -f "${mark}" ];then
		echo "$info" > ${mark} || exit ${STATE_WARNING}
		chown nagios.nagios ${mark}
		echo "This script is First run! ${info}"
		exit ${STATE_OK}
fi


