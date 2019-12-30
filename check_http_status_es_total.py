#!/usr/bin/env python3

import re,sys,datetime,requests
from elasticsearch import Elasticsearch
import datetime,sys,re,os
#import requests,dateparser
#import numpy as np
#import pandas as pd

es_index_argv = str(sys.argv[1])
http_status = str(int(sys.argv[2]))

time = datetime.datetime.utcnow()
date_now = time.strftime('%Y-%m-%d')
es_index = es_index_argv + '*'
es = Elasticsearch()

bodys = bodys = {
  "query": {
    "bool": {
      "must": [
        { "match": { "status":   http_status        }}
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
    res = es.search(index=es_index, body=bodys)
except:
    print(es_index+' is not found!')
    sys.exit(3)

print(res['hits']['total'])
sys.exit(0)
