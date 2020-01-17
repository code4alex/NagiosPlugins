#!/bin/bash

#SET TEMP DIR
tmp="/tmp/tmp_$$"

#SET EXIT STATUS AND COMMAND
trap "exit 1"           HUP INT PIPE QUIT TERM
trap "test -f ${tmp} && rm -f ${tmp}"  EXIT

my_date=`date -d '-1min' +"%FT%T"|sed 's/..$//'`

tail -n 5000 /data/log/sso-ss-traffic.log|grep "${my_date}"|\
jq -r '[(.username,.traffic,.port)]|@tsv' > ${tmp}

sum=`awk '{sum+=$2}END{print sum}' ${tmp}`

echo ${sum}|grep -oP '\d+' || exit 0

ip=`/sbin/ip addr list|grep -E "${dev_name}$"|grep -oP '\d{1,3}(\.\d{1,3}){3}'|grep -Ev '^127|255$'|head -n1`
hostname=`hostname`
timetamp=`date -d now +"%s%N"`

cat ${tmp}|\
while read user tr port
do
    percent=`echo "scale=2;${tr}/${sum}*100"|bc -l`
    echo -en "${user}\t${percent}\t${port}\n"
done|sort -nrk2|\
awk -v hostname=${hostname} -v ip=${ip} -v timetamp=${timetamp} '$2>0{print "ss_persent,host="hostname",server="ip",username="$1",persent="$2" port="$3" "timetamp}'
