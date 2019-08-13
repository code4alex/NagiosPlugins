#!/usr/bin/env python3
# nat 流量脚本
# need this
# pip3 install aliyun-python-sdk-core aliyun-python-sdk-cms

from aliyunsdkcore import client
from aliyunsdkcms.request.v20190101 import DescribeMetricListRequest
from datetime import datetime, timedelta
import time,json,sys
#from pprint import pprint

start_datetime = datetime.now() - timedelta(minutes=3)
start_time = start_datetime.strftime("%F %T")

# 例子
# 详见：https://help.aliyun.com/document_detail/28622.html

# 项目
project = 'my_project'
# 监控类型
category = 'nat'
# 实例列表
instance_list = ['eip-xxx1','eip-xxx2']
# 初始化客户端，填写accessKeyId, accessSecret, region_id
clt = client.AcsClient('accessKeyId','accessSecret','region_id')

# 初始化请求对象
request = DescribeMetricListRequest.DescribeMetricListRequest()
request.set_accept_format('json')
request.set_Namespace("acs_vpc_eip");
request.set_Period("60");
request.set_StartTime(str(start_time))
# 返回数据条数
request.set_Length("1")

# 日志模板
# json
#msg_template = """{"timestamp":%s,"project":"%s","category":"%s","instanceId":"%s","%s":%s}"""
# influx
msg_template = """ali_nat_metric,project=%s,category=%s,instanceId=%s %s=%s %s"""
# 实例id模板
instanceId_template = """{'instanceId':'%s'}"""

# 查询的指标字段
# 详见：https://help.aliyun.com/document_detail/28619.html?spm=a2c4g.11186623.2.13.7ee07751cneJUc
metric_list = ['net_rx.rate','net_tx.rate']

for id in instance_list:
    instanceId_str = instanceId_template % (id)
    request.set_Dimensions(instanceId_str)

    for metric in metric_list:
        request.set_MetricName(metric)
        result = clt.do_action_with_exception(request)
        #json_raw = json.loads(result)
        json_raw = json.loads(result.decode('utf-8'))
        try:
            data = json.loads(json_raw['Datapoints'][1:-1])
        except:
            continue
        # json
        #msg = msg_template % (data['timestamp'],project,category,data['instanceId'],metric,data['Value'])
        # influx
        msg = msg_template % (project,category,data['instanceId'],metric,data['Value'],data['timestamp']*1000000)
        print(msg)
        time.sleep(2)
#sys.exit(0)
