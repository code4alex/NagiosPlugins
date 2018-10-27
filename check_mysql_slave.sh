#!/bin/bash

#Slave_SQL_Running
  
export LANG=en_US.UTF-8

STATE_OK=0
STATE_WARNING=1
STATE_CRITICAL=2
STATE_UNKNOWN=3

error_info=`sudo /usr/bin/mysql -umonitor -p'password' -s -A -C \
-e "show slave status\G;"|\
grep -P 'Slave_.+_Running:'|\
awk 'BEGIN{ORS=";"}$0!~/: Yes/{print $1,$2}'`

#echo $error_info

test -n "${error_info}" ||\
eval "echo MySQL slave status is OK!;exit ${STATE_OK}"

echo "MySQL slave status is WARNING! ${error_info}" && exit ${STATE_WARNING}
