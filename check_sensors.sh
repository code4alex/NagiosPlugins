#!/bin/bash

#set nagios status
STATE_OK=0
STATE_WARNING=1
STATE_CRITICAL=2
STATE_UNKNOWN=3

usage () {
        echo -en "USAGE: $0 -d coretemp-isa-0000 -w 35 -c 60\n" 1>&2
        exit ${STATE_WARNING}
}

check_para () {
local para="$1"
echo "${para}"|\
grep -E '^[0-9]+$' >/dev/null 2>&1 ||\
eval "echo Error parameters: ${para} . Please enter numbers. 1>&2;exit ${STATE_WARNING}"
}

while getopts d:c:w: opt
do
        case "$opt" in
        d) 
                sensors "$OPTARG" >/dev/null || exit ${STATE_UNKNOWN}
                dev="$OPTARG"
        ;;
        c) 
                check_para "$OPTARG"
                critical="$OPTARG"
                ;;
        w) 
                check_para "$OPTARG"
                warning="$OPTARG"
        ;;
        *) usage;;
        esac
done

shift $[ $OPTIND - 1 ]

if [ $# -gt 0 -o -z "${dev}" -o -z "${critical}" -o -z "${warning}" ];then
        usage
fi

temp=`sensors coretemp-isa-0000|grep -E '^Core'|awk -F'°' '{print $1}'|\
sed -r 's/\+//g;s/[ ]+/ /g'|awk '{num++;sum+=$3}END{print sum/num}'`

message () {
    local stat="$1"
        local value="$2"
    echo "${dev} Temperature is ${stat} - ${temp}/${value}|temp=${temp};${warning};${critical};${min};${max}"
}

#pnp4nagios setting
min=0
max=150

[ `echo "(${total_int}-${warning}) < 0"|bc` -eq 1 ] && message "OK" "${warning}" && exit ${STATE_OK}
[ `echo "(${total_int}-${critical}) >= 0"|bc` -eq 1 ] && message "Critical" "${critical}" && exit ${STATE_CRITICAL}
[ `echo "(${total_int}-${warning}) >= 0"|bc` -eq 1 ] && message "Warning" "${warning}" && exit ${STATE_WARNING}
