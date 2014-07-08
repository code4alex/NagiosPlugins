#!/bin/bash

STATE_OK=0
STATE_WARNING=1
STATE_CRITICAL=2
STATE_UNKNOWN=3

export ORACLE_BASE=/u01/app/oracle
export ORACLE_HOME=$ORACLE_BASE/product/10.2.0/db_1
export ORACLE_SID=querydb
export GG_HOME=/u01/ggs
export NLS_LANG=AMERICAN_AMERICA.ZHS16GBK
export LD_LIBRARY_PATH=$ORACLE_CRS_HOME/lib:$ORACLE_HOME/lib:$GG_HOME:/usr/lib
export TNS_ADMIN=$ORACLE_HOME/network/admin
export ORA_OEMAGENT_DIR=$ORACLE_HOME/network/agent
export THREADS_FLAG=native
export PATH=$PATH:$ORACLE_CRS_HOME/bin:$ORACLE_HOME/bin:$GG_HOME
cd ${GG_HOME}
/usr/local/nagios/libexec/gg.exp >/dev/null 2>&1 || gg_exec='fail'
if [ "${gg_exec}" = 'fail' ];then
        echo '/usr/local/nagios/libexec/gg.exp execute error!'
        exit ${STATE_UNKNOWN}
fi

info=`/usr/local/nagios/libexec/gg.exp|awk '$4~/^00:0[3-9]:/ || $4~/^00:[^0]/ || $5~/^00:0[3-9]:/ || $5~/^00:[^0]/ || /ABENDED/{print $1,$2,$3,$4,$5}'| awk 'BEGIN{ORS=";"}{print}'`

#echo $info
if [ -z "${info}" ];then
        echo "check GG is OK!"
        exit ${STATE_OK}
else
        echo "check GG is WARNING! Error info: ${info}"
        exit ${STATE_CRITICAL}
fi
