#!/bin/bash

deny_hosts_file='/etc/hosts.deny'
my_date=`date -d "-1 minute" +"%a %b %d %H:%M:"`

#set exit status
STATE_OK=0
STATE_WARNING=1
STATE_CRITICAL=2
STATE_UNKNOWN=3

test -e ${deny_hosts_file} || eval "echo ${deny_hosts_file} not exsit!;exit ${STATE_UNKNOWN}"

deny_num=`grep "DenyHosts: ${my_date}" ${deny_hosts_file}|wc -l`

if [ ${deny_num} -gt 0 ];then
	echo "Check DenyHosts is WARNING! View details please type: less ${deny_hosts_file}"
	exit ${STATE_WARNING}
else
	echo "Check DenyHosts is OK!"
	exit ${STATE_OK}
fi
