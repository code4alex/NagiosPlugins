#!/bin/bash

#set exit status
STATE_OK=0
STATE_WARNING=1
STATE_CRITICAL=2
STATE_UNKNOWN=3

user=`id -un`

if [ "${user}" = "root" -o "${user}" = "nagios" ];then
	mark='/usr/local/nagios/libexec/check_NIC.mark'
	test -e ${mark} || echo "0" > ${mark}
	chown nagios.nagios ${mark}
else
	echo "Execute this script with root or nagios permissions!" 1>&2
	exit ${STATE_WARNING}
fi

#mark='/usr/local/nagios/libexec/check_NIC.mark'
#test -e ${mark} || echo "0" > ${mark}
#chown nagios.nagios ${mark}

last_num=`cat ${mark}`
RX_errs_RX_drop_TX_errs_TX_drop=`sed '1,2d' /proc/net/dev|\
awk '{RX_errs+=$4;RX_drop+=$5;TX_errs+=$12;TX_drop+=$13}END{print "RX_errs="RX_errs"\n""RX_drop="RX_drop"\n""TX_errs="TX_errs"\n""TX_drop="TX_drop}'`

eval ${RX_errs_RX_drop_TX_errs_TX_drop}

all_err_num=`echo "${RX_errs}+${RX_drop}+${TX_errs}+${TX_drop}"|bc`
NIC_info="RX_errs=${RX_errs};RX_drop=${RX_drop};TX_errs=${TX_errs};TX_drop=${TX_drop}"

#set pnp4nagios value
warning=0
critical=0
min=0
max=1000000

if [ "${last_num}" = "${all_err_num}" ];then
        echo "Check NIC is OK! ${NIC_info} | all_err_num=${all_err_num};${warning};${critical};${min};${max}"
        exit ${STATE_OK}
else
        echo "Check NIC is WARNING! ${NIC_info} | all_err_num=${all_err_num};${warning};${critical};${min};${max}"
        echo "${all_err_num}" > ${mark}
        exit ${STATE_WARNING}
fi
