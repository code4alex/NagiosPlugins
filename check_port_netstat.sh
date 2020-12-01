#!/bin/bash

#set exit status
STATE_OK=0
STATE_WARNING=1
STATE_CRITICAL=2
STATE_UNKNOWN=3

port_list="$1"

test -f ${port_list} ||\
eval "${port_list} not found!;exit 1"

#SET TEMP DIR
TMP_PATH="/tmp/tmp.$$"

test -d ${TMP_PATH}||\
mkdir -p ${TMP_PATH}

#SET EXIT STATUS AND COMMAND
trap "exit 1"           HUP INT PIPE QUIT TERM
trap "rm -rf ${TMP_PATH}"  EXIT

cat ${port_list}|grep -Ev '^$|^#'|sort -u|\
while read port
do
    netstat -nlpt|grep java|grep -v 127.0.0.1|awk '{print $4}'|awk -F':' '{print $2}' > ${TMP_PATH}/port.list
    grep -E "^${port}$" ${TMP_PATH}/port.list >/dev/null 2>&1 || echo -en "${port};" >> ${TMP_PATH}/error.msg
done

test -s "${TMP_PATH}/error.msg" ||\
eval "echo Check_port_netstat is OK!;exit 0"

port_msg=`cat ${TMP_PATH}/error.msg`
faild_count=`cat ${TMP_PATH}/error.msg|grep -oE ';'|wc -l`

echo "Check_port_netstat is CRITICAL! port: ${port_msg} count=${faild_count}|count=${faild_count};;;;" &&\
exit 2
