#!/bin/bash

export JAVA_HOME=/opt/jdk1.5.0_16
export PATH=$JAVA_HOME/bin:$ORACLE_HOME/bin:$PATH

STATE_OK=0
STATE_WARNING=1
STATE_CRITICAL=2
STATE_UNKNOWN=3

nagios_lib='/usr/local/nagios/libexec'
mark="${nagios_lib}/gc_count"

#gc_count=`pgrep -u posp java|\
#xargs -r -i jstat -gcutil  "{}"|\
#awk 'NR==2{print $(NF-2)}'`

gc_count=`cat /tmp/gc_count`

if [ ! -f "${mark}" ]; then
        mkdir -p ${nagios_lib}
        echo ${gc_count} > ${mark}
        chown nagios.nagios ${mark}
fi

last_gc_count=`cat ${mark}`

#set pnp4nagios value
warning=''
critical=''
min=0
max=1000

if [ "${gc_count}" = "${last_gc_count}" ];then
        echo "check gc count is OK! gc_count=${gc_count} | gc_count=${gc_count};${warning};${critical};${min};${max}"
        exit ${STATE_OK}
else
        echo "gc count has been changed! ${last_gc_count} -> ${gc_count}. | gc_count=${gc_count};${warning};${critical};${min};${max}"
        echo "${gc_count}" > ${mark}
        chown nagios.nagios ${mark}
        exit ${STATE_WARNING}
fi
