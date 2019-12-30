#!/usr/bin/env python3

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
        { "match": { "type":   "nginx-raw-access-log"        }},
        {"query_string": {"query": "NOT status:499 AND NOT status:401"}},
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

#scroll 告诉 Elasticsearch 把搜索上下文再保持一分钟。1m表示1分钟
size = 1000
query = es.search(index=es_index,body=query_json,scroll='1m',size=size)

results = query['hits']['hits']
total = query['hits']['total']
scroll_id = query['_scroll_id']

#divmod返回一个元祖，第一个元素，就是要分页数
#for i in range(0, int(total/100)+1):
for i in range(divmod(total, size)[0] + 1):
    # scroll参数必须指定否则会报错
    query_scroll = es.scroll(scroll_id=scroll_id,scroll='1m')['hits']['hits']
    results += query_scroll
#print(results)

mdata = query.get("hits").get("hits")  # 返回数据，它是一个列表类型
if not mdata:
    print('%s mdata is empty!' % es_index)
    sys.exit(3)

def message(url_msg,html_status,status,sum,warning,critical):
    message_template = """%s - http %s status is %s! count=%s/min"""
    rrd_template = """|count=%s;%s;%s;"""
    message = message_template % (status,html_status,status,sum)
    rrd_msg = rrd_template % (sum,warning,critical)
    msg = message + '\n' + url_msg + '\n' + rrd_msg
    return(msg)

html_status = '4xx 5xx'
status_url_list = list()

#for hit in res['hits']['hits']:
for hit in results:
    status_url_list.append([hit["_source"]['status'],hit["_source"]['url']])

df = pd.DataFrame(status_url_list,columns=['status','url'])
url_group = df.groupby(['status','url'])['url'].count().reset_index(name='count').sort_values(['count'], ascending=False)
s = url_group.reset_index(drop=True)
s.index = s.index + 1

if total == 0:
    url_msg = ''
else:
    #url_msg = url_group.to_string()
    url_msg = s.head(10).to_string()

if total >= critical:
    print(message(url_msg,html_status,'critical',total,warning,critical))
    sys.exit(2)
elif total >= warning:
    print(message(url_msg,html_status,'warning',total,warning,critical))
    sys.exit(1)
else:
    print(message(url_msg,html_status,'ok',total,warning,critical))
    sys.exit(0)
