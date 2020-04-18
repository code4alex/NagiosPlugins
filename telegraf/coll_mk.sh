#!/bin/bash

timetamp=`date -d now +"%s%N"`
sudo su - mk -c 'lq "GET services\nColumns: host_name description state\nFilter: state > 0"'|\
awk -F';' -v timetamp="$timetamp" '{print "mk_get_services,hostname="$1" description=\""$2"\",status="$3" "timetamp}'

sudo su - mk -c 'lq "GET hosts\nColumns: host_name address"'|\
awk -F';' -v timetamp="$timetamp" '{print "mk_get_hosts,hostname="$1",address="$2" count=1 "timetamp}'
