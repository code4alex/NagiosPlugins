#!/bin/bash

#nagios exit code
STATE_OK=0
STATE_WARNING=1
STATE_CRITICAL=2
STATE_UNKNOWN=3

#help
help () {
        echo -en "Usage: $0 -H <host> -p <port>\nFor example:\t$0 -H 192.168.0.6 -p 8819\n" 1>&2
        exit 1
}

#input
while getopts p:H: opt
do
        case "$opt" in
        p) port="$OPTARG";;
        H) ip="$OPTARG";;
        *) help;;
        esac
done
shift $[ $OPTIND - 1 ]

if [ $# -gt 0 -o -z "${port}" -o -z "${ip}" ];then
        help
fi

info=`netstat -ptn|grep 'ESTABLISHED'|grep "${ip}:${port}"`

if [ -n "${info}" ];then
        echo "Check ip: ${ip} port: ${port} is OK!"
        exit ${STATE_OK}
else
        echo "Check ip: ${ip} port: ${port} is WARNING! Can not connect to the target address!"
        exit ${STATE_WARNING}
fi
