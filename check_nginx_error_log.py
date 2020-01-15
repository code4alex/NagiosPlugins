#!/usr/bin/env python3

#usage
#/usr/local/nagios-plugins/check_nginx_error_log.py nginx_raw_error_log 50 100
import re,sys,datetime,requests
from elasticsearch import Elasticsearch
import datetime,sys,re,os
import numpy as np
import pandas as pd

es_index_argv = str(sys.argv[1])
warning = int(sys.argv[2])
critical = int(sys.argv[3])

time = datetime.datetime.utcnow()
date_now = time.strftime('%Y-%m-%d')
es_index = es_index_argv + '*'
es = Elasticsearch()
query_json = {
  "query": {
    "bool": {
      "must": [
        { "match": { "type":   "nginx_raw_error_log"        }},
      ],
      "filter": {
       "range": {
      "timestamp": {
      "gte": "now-2m",
      "lt": "now-1m"
      }
        }
    }
    }
  }
}

try:
    res = es.search(index=es_index, body=query_json)
except:
    print(es_index+' is not found!')
    sys.exit(3)

#print(res['hits']['total'])
total = int(res['hits']['total'])

def message(status,total,warning,critical):
    message_template = """%s - nginx error log is %s! count=%s/min"""
    rrd_template = """|count=%s;%s;%s;"""
    message = message_template % (status,status,total)
    rrd_msg = rrd_template % (total,warning,critical)
    msg = message + rrd_msg
    return(msg)

if total >= critical:
    print(message('Critical',total,warning,critical))
    sys.exit(2)
elif total >= warning:
    print(message('Warning',total,warning,critical))
    sys.exit(1)
else:
    print(message('OK',total,warning,critical))
    sys.exit(0)
