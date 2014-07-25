#!/bin/bash

#set nagios status
STATE_OK=0
STATE_WARNING=1
STATE_CRITICAL=2
STATE_UNKNOWN=3

user_id=`whoami`
time_now=`date -d now +"%F %T"`
FGC_count=`pgrep -u ${user_id} java|xargs -r -i jstat -gcutil "{}"|tail -n 1|awk '{print $(NF-2)}'`
info=`echo "TIME=\"${time_now}\";FGC=${FGC_count}"`

mark="/tmp/full_gc.${user_id}"

marking () {
        echo "${info}" > ${mark} || exit ${STATE_WARNING}
        chmod 755 ${mark}
}

if [ ! -f "${mark}" ];then
                marking
                echo "This script is First run! ${info}"
                exit ${STATE_OK}
else
                old_info=`cat ${mark}`
                eval "${old_info}"
                OLD_TIME="${TIME}";OLD_FGC="${FGC}"
                if [ -z "${OLD_TIME}" -o -z "${OLD_FGC}" ];then
                        echo "Data Error: ${old_info}" 1>&2
                        marking
                        exit ${STATE_WARNING}
                fi
fi

if [ -n "${info}" ];then
                eval "${info}"
                sec_now=`date -d "${TIME}" +"%s"`
                sec_old=`date -d "${OLD_TIME}" +"%s"`
		FGC_num=`echo "${FGC}-${OLD_FGC}"|bc`
                sec=`echo "${sec_now}-${sec_old}"|bc|sed 's/-//'`
                marking
#debug
#               echo $sec $OLD_FGC ${FGC} $FGC_num
else
               echo "Can not read ${source_file}" 1>&2
               exit ${STATE_WARNING}
fi

GC_tmp="/tmp/gc_tmp.${user_id}"
if [ `echo "${sec} > 280"|bc` -eq 1 ];then
		echo "${FGC_num}" > ${GC_tmp}
		chmod 755 ${GC_tmp}
fi
