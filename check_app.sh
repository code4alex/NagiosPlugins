#!/bin/bash

STATE_OK=0
STATE_WARNING=1
STATE_CRITICAL=2
STATE_UNKNOWN=3

tmp_file="/tmp/check_app.$$"

trap "exit 1"           HUP INT PIPE QUIT TERM
trap "test -f ${tmp_file} && rm -f ${tmp_file}"  EXIT

find /data/ -type f -name 'appctl.sh' 2>/dev/null|grep -Ev 'bakup|logs|others'|\
awk -F'/' '{print $(NF-1)}'|\
while read app
do
    ps -eo args|grep java|grep "${app}" >/dev/null 2>&1 ||\
        echo "${app} fail" >> ${tmp_file} &&\
        echo "${app} ok" >> ${tmp_file}
done

fail=`grep -E "fail$" "${tmp_file}"|wc -l`
ok=`grep -E "ok$" "${tmp_file}"|wc -l`

if [ ${fail} -gt 0 ];then
    apps=`awk 'BEGIN{ORS=";"}$NF~/fail/{print $1}' ${tmp_file}`
    echo "WARNING - ${apps} is DOWN! ok=${ok} fail=${fail}|ok=${ok};;; fail=${fail};;;"
    exit ${STATE_CRITICAL}
else
    echo "OK - KreditPintar_biz is OK! ok=${ok} fail=${fail} |ok=${ok};;; fail=${fail};;;"
    exit ${STATE_OK}
fi
