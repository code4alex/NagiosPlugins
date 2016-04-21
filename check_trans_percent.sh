#!/bin/bash

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
        echo -en "Usage: $0 -u <user> -s <passwd> -d <DBname> -w <percent>\nFor example:\t$0 -u db_user -s db_password -d oracle_sid -w 30\n" 1>&2
        exit 1
}

while getopts u:s:d:w: opt
do
        case "$opt" in
        u) user="$OPTARG";;
        s) passwd="$OPTARG";;
        d) oracle_db="$OPTARG";;
        w) percent_warning="$OPTARG";;
        *) help;;
        esac
done
shift $[ $OPTIND - 1 ]

if [ $# -gt 0 -o -z "${user}" -o -z "${passwd}" -o -z "${oracle_db}" ];then
        help
fi

DATE=`date -d now +"%Y%m%d%H%M"`

q_date=`date -d now +"%Y%m%d"`
q_min=`date -d -3min +"%H%M%S"`
q_max=`date -d -1min +"%H%M%S"`

${SQLPLUS} -S ${user}/${passwd}@${oracle_db} << EOF > ${TEMP}
set heading off;
set trimout on;
set trimspool on;
select count(*),sum(amt)/100 from bmp.t_jnls where tdate='${q_date}' and ttime>='${q_min}' and ttime<='${q_max}';
EOF

#cat ${TEMP}
query=`cat ${TEMP}|grep -Ev '^$'|sed -r 's/^[ ]+//g'`

trans_number=`echo ${query}|awk '{print $1}'`
trans_cash=`echo ${query}|awk '{print $2}'`

nagios_path='/usr/local/nagios/libexec'
test -d ${nagios_path} || mkdir -p ${nagios_path} && mark="${nagios_path}/trans_percent.mark"

marking () {
        echo "${trans_number} ${trans_cash}" > ${mark} || exit ${STATE_WARNING}
        chown oracle ${mark}
}

if [ ! -f "${mark}" ];then
                marking
                echo "This script is First run! ${info}"
                exit ${STATE_OK}
else
                                old_trans_number=`cat $mark|awk '{print $1}'`
                                old_trans_cash=`cat $mark|awk '{print $2}'`
                                if [ -z "${old_trans_number}" -o -z "${old_trans_cash}" ];then
                                        old_info=`cat $mark|head -n 1`
                                        echo "Data Error: ${old_info}" 1>&2
                                        marking
                                        exit ${STATE_WARNING}
                                fi
fi

echo ${trans_number}|grep -E '[0-9]+' >/dev/null 2>&1 || database_return='fail'
[ "${database_return}" = 'fail' ] && echo "oracle query is ${database_return}!" && exit ${STATE_UNKNOWN}

message () {
local stat="$1"
        echo "交易波动 is $stat.波动百分比:${percent}% 阀值:(+-)$percent_warning% 当前笔数:${trans_number} 之前笔数:${old_trans_number}|percent=$percent;;;"
}

if [ `echo "(${old_trans_number}-${trans_number}) < 0"|bc` -eq 1 ];then
        percent=`echo "scale=2;${old_trans_number}/${trans_number}*100-100"|bc|awk -F'.' '{print $1}'|sed -r 's/^-//'`
else
        percent=`echo "scale=2;${trans_number}/${old_trans_number}*100-100"|bc|awk -F'.' '{print $1}'|sed -r 's/^-//;s/^/-/'`
fi

marking
percent_value=`echo $percent|sed -r 's/^-//'`
[ `echo "($percent_value-$percent_warning) > 0"|bc` -eq 1 ] && message "CRITICAL" && exit ${STATE_CRITICAL} || message "OK" && exit ${STATE_OK}
