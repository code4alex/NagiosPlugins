#!/bin/bash

#set nagios status
STATE_OK=0
STATE_WARNING=1
STATE_CRITICAL=2
STATE_UNKNOWN=3

usage (){
        echo -en "Usage: $0 -d <user> -w <number of warning> -c <number of critical> \nFor example:\t$0 -u <user> -w 2 -c 5\n" 1>&2
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
            echo "\"${num_int}\" must be greater than 0!" 1>&2
            exit ${STATE_WARNING}
        fi
    fi
}

check_user (){
        local user_id="$1"
        id ${user_id} >/dev/null || usage
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

while getopts w:c:u: opt
do
        case "$opt" in
                w)
                        check_num "$OPTARG"
                        warning=`echo "$OPTARG"|bc`
                ;;
                c)      
                        check_num "$OPTARG"
                        critical=`echo "$OPTARG"|bc`
                ;;
        u)
                        user_id="$OPTARG"
                        check_user "${user_id}"
                ;;
        *)
                        usage
                ;;
        esac
done

shift $[ $OPTIND - 1 ]

if [ -z "${user_id}" -o -z "${warning}" -o -z "${critical}" ];then
        usage
fi

check_parameter "${warning}" "${critical}"

gc_tmp="/tmp/gc_tmp.${user_id}"

full_gc="/tmp/full_gc.${user_id}"
FGC_info=`cat ${full_gc}|awk -F';' '{print $(NF)}'`

[ -n ${FGC_info} ] && eval "${FGC_info}" 

test -f ${gc_tmp} && gc_num=`cat ${gc_tmp}|awk '{print $1}'` || exit ${STATE_OK}

gc_num_int=`echo "${gc_num}*1"|bc`

message () {
local stat="$1"
local threshold="$2"
#local sign="$3"
#set pnp4nagios value
local warning="${warning}"
local critical="${critical}"
local min=${min}
local max=${max}
echo "Check gc is ${stat}! FGC: ${FGC} Growing: ${gc_num_int} threshold: ${threshold}|FGC=${FGC};${warning};${critical};${min};${max}"
}

[ ${gc_num_int} -lt ${warning} ] && message "OK" "${warning}" && exit ${STATE_OK}
[ ${gc_num_int} -ge ${critical} ] && message "Critical" "${critical}" && exit ${STATE_CRITICAL}
[ ${gc_num_int} -ge ${warning} ] && message "Warning" "${warning}" && exit ${STATE_WARNING}
