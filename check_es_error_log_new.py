#!/usr/bin/env python3

import re,sys,datetime
from elasticsearch import Elasticsearch

title = str(sys.argv[1])
es_index = str(sys.argv[2])
time = datetime.datetime.utcnow()
date_now = time.strftime('%Y-%m-%d')
es = Elasticsearch()

query_json = {
  "query": {
    "bool": {
      "must": [
        { "match": { "type":   "cboss-log"        }},
      ],
      "filter": {
       "range": {
      "timestamp": {
      "gte": "now-1m",
      "lt": "now"
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
    sys.exit(0)

ignore_re = re.compile('sendDueNotification|fcAssignByCollectionArea|fcAssignByCollectionArea|autoImportDpd0CollectionOrder|autoRetryImportCollectionOrder|Get OKP Products failed')
no_error_re = re.compile('INFO')
error_re = re.compile('ERROR')

error_list = []
total = 0
for hit in results:
    if re.search(no_error_re,hit["_source"]['message']) or re.search(ignore_re,hit["_source"]['message']):
        continue
    if re.search(error_re,hit["_source"]['message']):
        err_msg = str("%(message)s" % hit["_source"])
        error_list.append(err_msg)
        total += 1

if total > 0:
    stats = 'WARNING'
    print('total: '+ str(total))
    for msg in sorted(error_list):
        print(msg)
    print('|'+"error="+ str(total))
    sys.exit(1)
else:
    stats = 'OK'
    print(title+" is OK.| error=0")
    sys.exit(0)
