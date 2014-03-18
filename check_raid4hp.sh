#!/bin/bash

#set nagios status
STATE_OK=0
STATE_WARNING=1
STATE_CRITICAL=2
STATE_UNKNOWN=3

help () {
        local command=`basename $0`
        echo "NAME
        ${command} -- check raid status for HP388G
SYNOPSIS
        ${command} [OPTION]
DESCRIPTION
        -d slot id=<number>
        -w warning=<number of disk for failed>
        -c critical=<number of disk for failed>
USAGE:
        $0 -w 1 -c 2 -d 0" 1>&2
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
while getopts w:c:d: opt
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
                d)
                        slot_id=$OPTARG
                        check_num "${slot_id}"
                ;;
                *) help;;
        esac
done
shift $[ $OPTIND - 1 ]

[ $# -gt 0 -o -z "${warning}" -o -z "${critical}" -o -z "${slot_id}" ] && help

if [ -n "${warning}" -a -n "${critical}" ];then
        if [ ${warning} -ge ${critical} ];then
                echo "-w ${warning} must lower than -c ${critical}!" 1>&2
                exit ${STATE_UNKNOWN}
        fi
fi

hp_cmd="/usr/sbin/hpacucli ctrl slot=${slot_id} show config detail"
#eval ${hp_cmd} > ${info_tmp} 2>&1 || stat='error'

info_tmp="/tmp/hpacucli.root.${slot_id}"

test -f ${info_tmp} ||\
eval "echo Please type \'${hp_cmd} \> ${info_tmp}\' to crontab for root!;exit ${STATE_WARNING}"

failed_count=`cat ${info_tmp} |grep 'Failed'|wc -l`

if [ "${failed_count}" == '0' ];then
        disk_stat='OK'
else
        disk_stat='Failed'
fi

info=`cat ${info_tmp}|\
awk '
#$0~/ '${disk_stat}'/{stat+=1;stat_info[$0]+=$1};
$0~/Failed/{stat+=1;stat_info[$0]+=$1};
END{
OFS=";"
ORS=";"
for (disk in stat_info)
{print disk;}
}'|sed -r 's/[ ][ ]+//g'`

#echo "${info}"
message () {
    local stat="$1"
    echo "RAID is ${stat}. ${info} | Failed status=${failed_count};${warning};${critical};${min};${max}"
}

#pnp4nagios setting
min=0
max=10

if [ "${failed_count}" == '0' ];then
        message "OK" && exit ${STATE_OK}
else
        message "Failed" && exit ${STATE_CRITICAL}
fi
