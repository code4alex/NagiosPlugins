#!/bin/bash

STATE_OK=0
STATE_WARNING=1
STATE_CRITICAL=2
STATE_UNKNOWN=3

tmp_data="/tmp/data.$$"

trap "exit 1"           HUP INT PIPE QUIT TERM
trap "test -f ${tmp_data} && rm -f ${tmp_data}"  EXIT

make_url(){
    local date="$1"
    url="http://192.168.4.99:8188/monitor/queryCount/getQueryCount?startDate=${date}&endDate=${date}&serviceCategory=IDENTITY_CHECK&accountId=3170330"
    echo "${url}"
}

day=7

for i in `seq ${day}`
do
    count=`echo ${i}+1|bc`
    my_date=`date -d "-${i}day" +"%F"`
    url=`make_url "${my_date}"`
    curl -s "$url" ||\
    eval "echo HttpUrlConnection fail!${url};exit 1"
done|grep -oP 'queryCount.+?}'|\
sed -r 's/["|}]//g;s/:/ /' >> ${tmp_data}

avg_query_count=`awk -v day="${day}" '{sum+=$2}END{print sum/day}' ${tmp_data}`
echo ${avg_query_count}
yesterday=`date -d "-1day" +"%F"`
query_count=`make_url "${yesterday}"|xargs -r -i curl -s '{}'|grep -oP 'queryCount.+?}'|sed -r 's/["|}]//g;s/:/ /'|awk '{print $2}'`
echo "${query_count}"

persent=`echo "(${query_count}-${avg_query_count})/${avg_query_count}"|bc`
abs_persent=`echo "${persent}"|sed '/-//'`
if [ ${abs_persent} -ge 10 ];then
    echo ""
else
    echo ""
fi
