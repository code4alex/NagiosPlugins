#!/bin/bash

#检测交易汇总
oracle_profile='/home/oracle/.bash_profile'

test -f ${oracle_profile} && source ${oracle_profile}

SQLPLUS="${ORACLE_HOME}/bin/sqlplus"

STATE_OK=0
STATE_WARNING=1
STATE_CRITICAL=2
STATE_UNKNOWN=3

TEMP="/tmp/check_bat_temp.$$"

#SET EXIT STATUS AND COMMAND
trap "exit 1"           HUP INT PIPE QUIT TERM
trap "rm -f ${TEMP}"  EXIT

help () {
        echo -en "Usage: $0 -u <user> -s <passwd> -d <DBname>\nFor example:\t$0 -u db_user -s db_password -d oracle_sid\n" 1>&2
        exit 1
}

while getopts u:s:d:w:c: opt
do
        case "$opt" in
        u) user="$OPTARG";;
        s) passwd="$OPTARG";;
        d) oracle_db="$OPTARG";;
		w) warning="$OPTARG";;
		c) critical="$OPTARG";;
        *) help;;
        esac
done
shift $[ $OPTIND - 1 ]

if [ $# -gt 0 -o -z "${user}" -o -z "${passwd}" -o -z "${oracle_db}" -o -z "$warning" -o -z "$critical" ];then
        help
fi

${SQLPLUS} -S ${user}/${passwd}@${oracle_db} << EOF > ${TEMP}
set heading off;
set trimout on;
set trimspool on;
select count(*) "交易笔数",to_char(sum(amt)) "交易额" from bmp.t_jnls where tdate = to_char (sysdate,'yyyymmdd') and transid='3' and rspcode='00';
EOF

#cat ${TEMP}
#exit
query=`cat ${TEMP}|grep -Ev '^$'|sed -r 's/^[ ]+//g'`

trans_number=`echo ${query}|awk '{print $1}'`
trans_cash=`echo ${query}|awk '{print $2}'`
#deal_count=`echo "${query}*1"|bc`

echo ${trans_number}|grep -E '[0-9]+' >/dev/null 2>&1 || database_return='fail'
[ "${database_return}" = 'fail' ] && echo "oracle query is ${database_return}!" && exit ${STATE_UNKNOWN}

message () {
local stat="$1"
        echo "交易笔数 is $stat.笔数:${trans_number} 金额:${trans_cash}|TRANS=$trans_number;;;;MONEY=$trans_cash;;;;"
}

[ "${trans_number}" = '0' ] && message "CRITICAL" && exit ${STATE_CRITICAL}
[ `echo "(${trans_cash}-${critical}) >= 0"|bc` -eq 1 ] && message "Critical" && exit ${STATE_CRITICAL}
[ `echo "(${trans_cash}-${warning}) >= 0"|bc` -eq 1 ] && message "Warning" && exit ${STATE_WARNING}
message "OK" && exit ${STATE_OK}
