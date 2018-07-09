#!/bin/bash

#curl 'http://graylog.server.local:9000/api/search/universal/absolute/export?query=nginx_version%3A1.6.x%20AND%20response%3A%5B400%20TO%20504%5D&from=2018-07-08%2008%3A51%3A00.000&to=2018-07-09%2008%3A52%3A00.000&fields=response' --user admin:passwd

graylog_url='http://graylog.server.local:9000/api/search/universal/absolute/export?'
condition='query=nginx_version%3A1.6.x%20AND%20response%3A%5B200%20TO%20504%5D&'
fields='fields=response'

time_from=`date -d -1min +'%F %H:%M:00.000'`
time_to=`date -d now +'%F %H:%M:00.000'`
time=`echo "from=${time_from}&to=${time_to}&"|sed 's/ /%20/g;s/:/%3A/g'`
#echo "${time}"

STATE_OK=0
STATE_WARNING=1
STATE_CRITICAL=2
STATE_UNKNOWN=3

tmp_file="/tmp/html.stat.$$"
trap "exit 1"           HUP INT PIPE QUIT TERM
trap "test -f ${tmp_file} && rm -f ${tmp_file}"  EXIT

url="${graylog_url}${condition}${time}${fields}"

msg=`curl -s --user admin:passwd ${url}|\
sed 1d|\
awk -F '"' 'BEGIN{OFS=":";ORS=";"}{stats[$(NF-1)]+=1}END{for (stat in stats) {print stat,stats[stat]}}'`
#echo "${msg}"

line=`echo "${msg}"|sed 's/:/,/g;s/;/\n/g'`

stat_code='200
403
404
499
500
501
502'

for stat in ${stat_code}
do
    number=`echo -e "${line}"|grep -E "^${stat}"|awk -F',' '{print $NF}'`
    test -z ${number} && number='0'
    echo -en "Code_${stat}=${number};;;; "
done > ${tmp_file}

rrd_data=`cat ${tmp_file}|head -n1`
#Code_200=141;;;; Code_206=0;;;; Code_302=0;;;; Code_304=0;;;; Code_403=0;;;; Code_404=0;;;; Code_499=0;;;; Code_500=0;;;; Code_502=0;;;; 
total=`echo -e "${line}"|awk -F',' '{sum+=$NF}END{print sum}'`

output=`echo -e "${line}"|awk -F',' 'BEGIN{OFS=":";ORS=","}{print "Code_"$1,$2" "}'`

if [ -z "${total}" ];then
    echo "获取数据异常!" && exit ${STATE_UNKNOWN}
else 
    echo "HTML状态 - 访问次数: ${total} . ${output} | ${rrd_data}" && exit "${STATE_OK}"
fi
