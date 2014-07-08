#!/bin/bash

#ORACLE ENV
export ORACLE_BASE=/u01/app/oracle
export ORACLE_HOME=$ORACLE_BASE/product/10.2.0/db_1
export ORACLE_SID=querydb
export GG_HOME=/u01/ggs
export NLS_LANG=AMERICAN_AMERICA.ZHS16GBK
export LD_LIBRARY_PATH=$ORACLE_CRS_HOME/lib:$ORACLE_HOME/lib:$GG_HOME:/usr/lib
export TNS_ADMIN=$ORACLE_HOME/network/admin
export ORA_OEMAGENT_DIR=$ORACLE_HOME/network/agent
export THREADS_FLAG=native
export PATH=$PATH:$ORACLE_CRS_HOME/bin:$ORACLE_HOME/bin:$GG_HOME:/sbin/

SQLPLUS="${ORACLE_HOME}/bin/sqlplus"

STATE_OK=0
STATE_WARNING=1
STATE_CRITICAL=2
STATE_UNKNOWN=3

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

DATE=`date -d now +"%Y%m%d%H%M"`

query=`${SQLPLUS} -S ${user}/${passwd}@${oracle_db} << EOF
set heading off;
SELECT datas FROM POSP.DATA_MINING WHERE data_time = '${DATE}';
EOF`

echo ${query}|grep -E '^[0-9]+$' >/dev/null || query='0'

deal_count=`echo "${query}*1"|bc`

#echo ${deal_count}
message () {
        echo "Deal_count=${deal_count}|Deal_count=${deal_count};4000;5000;0"
}

if [ -n "${deal_count}" ];then
        message
        exit ${STATE_OK}
else
        exit ${STATE_UNKNOWN}
fi
