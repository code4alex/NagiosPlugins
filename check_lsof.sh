#!/bin/bash

#set nagios status
STATE_OK=0
STATE_WARNING=1
STATE_CRITICAL=2
STATE_UNKNOWN=3

usage (){
        echo -en "Usage: $0 -u <user> -w <warning> -c <critical>\n" 1>&2
        exit ${STATE_WARNING}
}

check_user (){
	local user_id="$1"
	id ${user_id} >/dev/null || exit ${STATE_WARNING}
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
            echo "\"${num_int}\" must be greater than 0!" 1>&2
            exit ${STATE_WARNING}
        fi
    fi
}

check_parameter () {
local warning="$1"
local critical="$2"
if [ -n "${warning}" -a -n "${critical}" ];then
    if [ ${warning} -ge ${critical} ];then
        echo "-w \"${warning}\" must lower than -c \"${critical}\"" 1>&2
        exit ${STATE_WARNING}
    fi
fi
}

message () {
local stat="$1"
#set pnp4nagios value
local info="${info}"
local open_files_num_int="${open_files_num_int}"
local warning="${warning}"
local critical="${critical}"
local min=${min}
local max=${max}
echo "Check lsof is ${stat}! ${info}|open files=${open_files_num_int};${warning};${critical};${min};${max}"
}

logging () {
local now_date=`date -d now +"%F %T"`
local log_path='/var/log/lsof'
local log_name=`date -d "now" +"%F"`
local info="${info}"
local user_id="${user_id}"
local uid=`id -u`

if [ "${uid}" == '0' ];then
    test -d ${log_path} || mkdir -p ${log_path}/
    chown nagios.nagios -R ${log_path}
fi

log="${log_path}/lsof_${user_id}_${log_name}.log"
echo "${now_date} ${info}"|sed 's/;/ /g' >> ${log}
test -f ${log} && chown nagios.nagios ${log}
}

while getopts w:c:u:l opt
do
        case "$opt" in
		w)
            warning=$OPTARG
            check_num "${warning}"
        ;;
        c)
            critical=$OPTARG
            check_num "${critical}"
        ;;
        u) 
			user_id="$OPTARG"
		;;
		l)
            log_status='on'
        ;;
        *) 
			usage
		;;
        esac
done

shift $[ $OPTIND - 1 ]

[ -z "${user_id}" -o -z "${warning}" -o -z "${critical}" ] && usage || check_user "${user_id}"

check_parameter "${warning}" "${critical}"

#info=`/usr/sbin/lsof -u ${user_id} 2>/dev/null|\
#awk 'BEGIN{OFS=": ";ORS=";"}NR>1{items[$1]++;sum++}END{print "Total",sum;for (item in items){print item,items[item]}}'`

lsof_info="/tmp/lsof.${user_id}"
if [ -f "${lsof_info}" ];then
        info=`cat ${lsof_info}`
else
        echo "\"${lsof_info}\" not exsit!" 1>&2
        exit ${STATE_WARNING}
fi

open_files_num_str=`echo ${info}|awk -F':|;' '{print $2}'`
if [ -z "${open_files_num_str}" ];then
	echo "echo \"run /usr/sbin/lsof -u ${user_id} 2>/dev/null error!Is Empty!" 1>&2
	exit ${STATE_WARNING}
fi 

open_files_num_int=`echo "${open_files_num_str}*1"|bc`
echo "${open_files_num_int}"|grep -E '^[0-9]+$' >/dev/null 2>&1||\
eval "echo \"run /usr/sbin/lsof -u ${user_id} 2>/dev/null error! Not output!\" 1>&2;exit ${STATE_WARNING}"

#logging
[ "${log_status}" == 'on' ] && logging

#SET PNP4NAGIOS 
min=0
max=10240

[ ${open_files_num_int} -lt ${warning} ] && message "OK" && exit ${STATE_OK}
[ ${open_files_num_int} -ge ${critical} ] && message "Critical" && exit ${STATE_CRITICAL}
[ ${open_files_num_int} -ge ${warning} ] && message "Warning" && exit ${STATE_WARNING}
