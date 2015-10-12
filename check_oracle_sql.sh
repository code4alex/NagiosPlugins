#!/bin/bash
#oracle的GBK返回与系统UTF8之间的转换

oracle_profile='/home/oracle/.bash_profile'

test -f ${oracle_profile} && source ${oracle_profile}

export NLS_LANG=AMERICAN_AMERICA.ZHS16GBK
export LANG=zh_CN.GBK

SQLPLUS="${ORACLE_HOME}/bin/sqlplus"

STATE_OK=0
STATE_WARNING=1
STATE_CRITICAL=2
STATE_UNKNOWN=3

TEMP="/tmp/check_bat_temp.$$"
TEMP1="/tmp/check_bat_temp1.$$"
TEMP2="/tmp/check_bat_temp2.$$"

#SET EXIT STATUS AND COMMAND
trap "exit 1"           HUP INT PIPE QUIT TERM
trap "rm -f ${TEMP} ${TEMP1} ${TEMP2}"  EXIT

help () {
        echo -en "Usage: $0 -u <user> -s <passwd> -d <DBname>\nFor example:\t$0 -u db_user -s db_password -d oracle_sid\n" 1>&2
        exit 1
}

while getopts u:s:d: opt
do
        case "$opt" in
        u) user="$OPTARG";;
        s) passwd="$OPTARG";;
        d) oracle_db="$OPTARG";;
        *) help;;
        esac
done
shift $[ $OPTIND - 1 ]

if [ $# -gt 0 -o -z "${user}" -o -z "${passwd}" -o -z "${oracle_db}" ];then
        help
fi

${SQLPLUS} -S ${user}/${passwd}@${oracle_db} << EOF > ${TEMP}
set heading off;
set trimout on;
set trimspool on;
set line 180;
SQL
EOF

#cat ${TEMP}
test -f ${TEMP} && iconv -f GBK -t UTF-8 ${TEMP} -o ${TEMP1}
export LANG=en_US.UTF-8
#cat ${TEMP1}
#exit 

cat ${TEMP1}|grep -E '[0-9]+|no rows selected' >/dev/null 2>&1 || database_return='fail'
[ "${database_return}" = 'fail' ] && echo "oracle query is ${database_return}!" && exit ${STATE_UNKNOWN}

FAIL=`cat ${TEMP1}|grep -Ev '^$'|grep -Ev 'selected|no'|awk 'NF=3{print}'|wc -l`

cat ${TEMP1}|grep -Ev '^$'|grep -Ev 'selected|no'|sed -r 's/^[ ]+//g'|awk 'NF=3{print}'|sort -n|\
while read mid m_time m_type
do
        echo "商户编号：${mid} 频繁交易告警，时间：${m_time} 消费类型：${m_type}"
done > ${TEMP2}

#echo "${query}"
#exit 

message () {
local stat="$1"
        echo -en "频繁交易告警 is $stat.\n`cat ${TEMP2}`\n|FAIL=$FAIL;;;"
}

if [ "${FAIL}" = '0' ];then
        message "OK" && exit ${STATE_OK}
else
        message "CRITICAL" && exit ${STATE_CRITICAL}
fi
