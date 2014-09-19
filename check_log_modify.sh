#!/bin/bash

#set nagios status
STATE_OK=0
STATE_WARNING=1
STATE_CRITICAL=2
STATE_UNKNOWN=3

#log_file="$1"

usage (){
        echo -en "Usage: $0 -f <file name>" 1>&2
        exit ${STATE_WARNING}
}

while getopts f: opt
do
        case "$opt" in
        f) log_file="$OPTARG";;
        *) usage;;
        esac
done

shift $[ $OPTIND - 1 ]

if [ -z "${log_file}" ];then
        usage
fi

file_time=`stat -c %y ${log_file}|awk '{print $1,$2}'`

file_now=`date -d "${file_time}" +"%F %H:%M"`
time_now=`date -d now +"%F %H:%M"`

#debug
#echo $file_now $time_now && exit 

if [ "${file_now}" == "${time_now}" ];then
        echo "${log_file} have a new message!"
        exit ${STATE_CRITICAL}
else
        echo "${log_file} is fine!"
        exit ${STATE_OK}
fi
