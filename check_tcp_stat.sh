#!/bin/bash

#nagios exit code
STATE_OK=0
STATE_WARNING=1
STATE_CRITICAL=2
STATE_UNKNOWN=3

#help
help () {
        echo -en "Usage: $0 -H <host> -p <port>\nFor example:\t$0 -H 192.168.0.6 -p 8819\n" 1>&2
        exit ${STATE_UNKNOWN}
}

check_num () {
	local num_str="$1"
	echo ${num_str}|grep -E '^[0-9]+$' >/dev/null 2>&1 || stat='not a number!'
	if [ "${stat}" = 'not a number!' ];then
   		echo "${num_str} ${stat}"
		help
	fi
}

message () {
	local stat="$1"
	echo "${stat} - Network Connections. Info: ${info} | Total_connection=${total_connections_int};${warning};${critical};${min};${max}"
}

#input
while getopts w:c:p:H:S: opt
do
        case "$opt" in
		w) warning=$OPTARG;;
        c) critical=$OPTARG;;
        p) port="$OPTARG";;
        H) ip="$OPTARG";;
		S) state="$OPTARG";;
        *) help;;
        esac
done
shift $[ $OPTIND - 1 ]

[ $# -gt 0 -o -z "${warning}" -o -z "${critical}" ] && help

[ ${warning} -gt ${critical} ] && echo "-w ${warning} must lower than -c ${critical}!" && exit ${STATE_UNKNOWN}

[ -n "${port}" ] && check_num "${port}"

if [ -n "${state}" ];then
	case "${state}" in
    	TIME_WAIT|FIN_WAIT|ESTABLISHED|CLOSING|SYN_SEND|TIMED_WAIT)
			info=`netstat -tn|grep "${state}"|grep "${ip}:${port}"|\
			awk 'BEGIN{OFS=": ";ORS=";"}{stats[$(NF)]+=1}END{for (stat in stats) {print stat,stats[stat];sum+=stats[stat]};print "Total",sum}'`
    		;;
    	*)
        	echo "This script not support ${state}" 1>&2
			exit 1
        	;;
	esac
else
	info=`netstat -tn|grep "${ip}:${port}"|\
	awk 'BEGIN{OFS=": ";ORS=";"}{stats[$(NF)]+=1}END{for (stat in stats) {print stat,stats[stat];sum+=stats[stat]};print "Total",sum}'`
fi

#info=`netstat -tn|grep 'ESTABLISHED'|grep "${ip}:${port}"`
[ -z "${info}" ] && message "UNKNOWN" && exit "${STATE_UNKNOWN}"

min=0
max=4096
total_connections_str=`echo "${info}"|grep -oP "Total: \d+"|awk -F':' '{print $2}'`
total_connections_int=`echo "${total_connections_str}*1"|bc`
echo "${total_connections_int}"|grep -E '^[0-9]+$' >/dev/null 2>&1 ||\
eval "echo ${total_connections_int} not a number!exit ${STATE_UNKNOWN}"

[ ${total_connections_int} -lt ${warning} ] && message "OK" && exit ${STATE_OK}
[ ${total_connections_int} -ge ${critical} ] && message "Critical" && exit ${STATE_CRITICAL}
[ ${total_connections_int} -ge ${warning} ] && message "Warning" && exit ${STATE_WARNING}
