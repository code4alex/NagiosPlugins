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
	${command} -- check network status
SYNOPSIS
	${command} [OPTION]
DESCRIPTION
	-H IP ADDRESS
	-p LOCAL PORT
	-S [TIME_WAIT|FIN_WAIT|ESTABLISHED|CLOSING|SYN_SEND|TIMED_WAIT|LISTEN]
	-w warning
	-c critical
USAGE:
Total connections:
	$0 -w 100 -c 200
Port:
	$0 -p 8819 -w 100 -c 200
Host and Port:
	$0 -H 192.168.0.6 -p 8819 -w 100 -c 200
Status:
	$0 -H 192.168.0.6 -p 8819 -S ESTABLISHED -w 100 -c 200" 1>&2
        exit ${STATE_WARNING}
}

check_num () {
	local num_str="$1"
	echo ${num_str}|grep -E '^[0-9]+$' >/dev/null 2>&1 || stat='not a number!'
	if [ "${stat}" = 'not a number!' ];then
   		echo "${num_str} ${stat}" 1>&2
		exit ${STATE_WARNING}
	fi
}

check_ip () {
	local ip_str="$1"
	echo "${ip_str}"|grep -P '^\d{1,3}(\.\d{1,3}){3}$' >/dev/null 2>&1 || str_stat='not a ip!'
	if [ "${ip_stat}" = 'not a ip!' ];then
        echo "${ip_str} ${stat}" 1>&2
		exit ${STATE_WARNING}
    fi
}

check_state () {
	local stat_str="$1"
	if [ -n "${stat_str}" ];then
		case "${stat_str}" in
                TIME_WAIT|FIN_WAIT|ESTABLISHED|CLOSING|SYN_SEND|TIMED_WAIT)
					cmd="netstat -nt|grep ${stat_str}"
                ;;
				LISTEN)
					cmd="netstat -ntl"
				;;
                *)
                    echo "This script not support ${stat_str}" 1>&2
                    exit 1
                ;;
		esac
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
		w) 
			warning=$OPTARG;;
        c) 
			critical=$OPTARG;;
        p) 
			port="$OPTARG"
			check_num "${port}"
		;;
        H) 
			ip="$OPTARG"
			check_ip "${ip}"
		;;
		S) 
			state="$OPTARG"
			check_state "${state}"
		;;
        *) help;;
        esac
done
shift $[ $OPTIND - 1 ]

[ $# -gt 0 -o -z "${warning}" -o -z "${critical}" ] && help
[ ${warning} -gt ${critical} ] && echo "-w ${warning} must lower than -c ${critical}!" && exit ${STATE_UNKNOWN}

if [ -z "${state}" ];then
	info=`netstat -tn|grep "${ip}:${port} "|\
	awk 'BEGIN{OFS=": ";ORS=";"}{stats[$(NF)]+=1}END{for (stat in stats) {print stat,stats[stat];sum+=stats[stat]};print "Total",sum}'`
else
	info=`eval "$cmd"|grep "${ip}:${port} "|\
	awk 'BEGIN{OFS=": ";ORS=";"}{stats[$(NF)]+=1}END{for (stat in stats) {print stat,stats[stat];sum+=stats[stat]};print "Total",sum}'`
fi

echo "${info}"|grep -E '[0-9]' >/dev/null 2>&1 || eval "echo Info is empty! 1>&2;exit ${STATE_UNKNOWN}"

min=0
max=4096
total_connections_str=`echo "${info}"|grep -oP "Total: \d+"|awk -F':' '{print $2}'`
total_connections_int=`echo "${total_connections_str}*1"|bc`
echo "${total_connections_int}"|grep -E '^[0-9]+$' >/dev/null 2>&1 ||\
eval "echo ${total_connections_int} not a number!exit ${STATE_UNKNOWN}"

[ ${total_connections_int} -lt ${warning} ] && message "OK" && exit ${STATE_OK}
[ ${total_connections_int} -ge ${critical} ] && message "Critical" && exit ${STATE_CRITICAL}
[ ${total_connections_int} -ge ${warning} ] && message "Warning" && exit ${STATE_WARNING}
