#!/usr/bin/env python3

import re,sys,datetime,requests
from elasticsearch import Elasticsearch
import datetime,sys,re,os
#import numpy as np
#import pandas as pd

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
        { "match": { "type":   "nginx-access-raw-log"        }},
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

print(res['hits']['total'])
sys.exit(0)
