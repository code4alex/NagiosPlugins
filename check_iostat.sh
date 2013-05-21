#!/bin/bash

#set exit status
STATE_OK=0
STATE_WARNING=1
STATE_CRITICAL=2
STATE_UNKNOWN=3

usage (){
        echo -en "Usage: $0 -d [disk] -w [warning] -c [critical]\nFor example:\t$0 -d /dev/sda1 -w 50 -c 80\n" 1>&2
        exit ${STATE_WARNING}
}

check_system (){
system_info=`head -n 1 /etc/issue`

case "${system_info}" in
        'CentOS release 5'*)
                system='centos5'
                ;;
        'Red Hat Enterprise Linux Server release 5'*)
                system='rhel5'
                ;;
        'Debian GNU/Linux 6'*)
                system='debian6'
                ;;
        'Debian GNU/Linux 7'*)
                system='debian7'
                ;;
        *)
                system='unknown'
                echo "This script not support ${SYSTEM_INFO}" 1>&2
                exit 1
                ;;
esac
}

check_pkg () {
local pkg="$1"
case "${system}" in
        'centos'*)
                rpm -q ${pkg} >/dev/null 2>&1 ||\
                        eval "echo iostat not install! Please type: yum install ${pkg};exit ${STATE_WARNING}"
                ;;
        'debian'*)
                dpkg -s ${pkg} >/dev/null 2>&1 ||\
                        eval "iostat not install! Please type: aptitude install ${pkg};exit ${STATE_WARNING}"
                ;;
esac
}

check_num () {
        echo $1|grep -E '^[0-9]+$' >/dev/null 2>&1 || stat='not a number!'
        if [ "${stat}" = 'not a number!' ];then
                echo "$1 is not a number!"
                usage
                exit ${STATE_UNKNOWN}
        fi
}

message () {
local stat="$1"
echo "${stat} - I/O stats util_rate=${io_util} | util_rate=${io_util};${warning};${critical};${min};${max}"
}

check_system

check_pkg "sysstat"

while getopts d:w:c: opt
do
        case "$opt" in
        d) dev_id="$OPTARG";;
        w) warning=$OPTARG;;
        c) critical=$OPTARG;;
        *) usage;;
        esac
done

shift $[ $OPTIND - 1 ]

if [ -z "${dev_id}" -o -z "${warning}" -o -z "${critical}" ];then
        usage
else
        [ ! -b "${dev_id}" ] && echo "Not found ${dev_id}" && usage
        for para_value in "${warning}" "${critical}"
        do
                check_num "${para_value}"
        done
        [ ${warning} -gt ${critical} ] && echo "-w ${warning} must lower than -c ${critical}!" && exit ${STATE_UNKNOWN}
        disk=`echo ${dev_id}|awk -F'/' '{print $NF}'`
fi

io_util=`iostat -dx 1 10 ${dev_id} |\
awk '
$NF~/[0-9]+\.[0-9][0-9]/{
util=$NF;
MaxUtil=MaxUtil?MaxUtil:util;
MaxUtil=(MaxUtil>util)?MaxUtil:util
}
END{
print MaxUtil
}'`

io_value=`echo "scale=0;${io_util}/1"|bc`

min=0
max=100
[ ${io_value} -lt ${warning} ] && message "OK" && exit ${STATE_OK}
[ ${io_value} -ge ${critical} ] && message "Critical" && exit ${STATE_CRITICAL}
[ ${io_value} -ge ${warning} ] && message "Warning" && exit ${STATE_WARNING}

exit ${STATE_UNKNOWN}
