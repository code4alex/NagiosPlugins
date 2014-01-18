#!/bin/bash

#set nagios status
STATE_OK=0
STATE_WARNING=1
STATE_CRITICAL=2
STATE_UNKNOWN=3

usage (){
        echo -en "Usage: $0 -d [ bond0|bond1 ]\nFor example:\t$0 -d bond0\n" 1>&2
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

dev="/proc/net/bonding/${dev_id}"

if [ ! -f ${dev} ];then
        echo "${dev_id} not exsit!" 1>&2
        usage
fi

#bond_info=`grep -E 'Currently Active Slave|MII Status|Slave Interface' ${dev}|\
#awk 'BEGIN{ORS=";"}{print}'`

bond_info=`grep -E 'Bonding Mode|Currently Active Slave|MII Status|Slave Interface' ${dev} |\
awk -F':' '
BEGIN{
ORS=" "
}
NR==1{print "Mode:"$2";"}
NR==2{print "Active:"$2}
$1~/MII Status/{print "is"$2";"}
$1~/Slave Interface/{print "Interface:"$2}
'`

#bond_active=`echo "${bond_info}"|awk -F';|: ' '{print $2}'`
bond_active=`grep -E 'Currently Active Slave' ${dev} | awk '{print $NF}'`

down_status=`echo ${bond_info}|awk 'BEGIN{RS=";";ORS=";"}/down/{print}'`

nagios_lib='/usr/local/nagios/libexec'

bond_mark="${nagios_lib}/${dev_id}_info"
if [ ! -f "${bond_mark}" ]; then
        mkdir -p ${nagios_lib}
        echo ${bond_active} > ${bond_mark}
fi

test -f ${bond_mark} && chown nagios.nagios ${bond_mark}

mark_value=`cat ${bond_mark}`

if [ "${bond_active}" != ${mark_value} ];then
        echo "${dev_id} has been changed! ${mark_value} --> ${bond_active}. ${bond_info}"
        echo "${bond_active}" > ${bond_mark}
        exit ${STATE_WARNING}
fi

if [ -n "${down_status}" ];then
		echo "${down_status}. ${bond_info}"
		exit ${STATE_WARNING}
fi

echo "${dev_id} is OK! ${bond_info}"
exit ${STATE_OK}
