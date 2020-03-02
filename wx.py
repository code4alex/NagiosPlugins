#!/usr/bin/python
#wxalter

import os
import sys
import json
import urllib,urllib2

def gettoken(corpid,corpsecret):
    gettoken_url = 'https://qyapi.weixin.qq.com/cgi-bin/gettoken?corpid=' + corpid + '&corpsecret=' + corpsecret
    try:
        token_file = urllib2.urlopen(gettoken_url)
        #print token_file.read()
    except urllib2.HTTPError as e:
        print e.code
        print e.read().decode("utf8")
        sys.exit()
    token_data = token_file.read().decode('utf-8')
    token_json = json.loads(token_data)
    token_json.keys()
    token = token_json['access_token']
    #print token
    return token
 

def senddata(access_token):
    send_url = 'https://qyapi.weixin.qq.com/cgi-bin/message/send?access_token=' + access_token
    email = os.getenv("NOTIFY_CONTACTEMAIL")
    #if email in userlist.keys():
    #    userid = userlist[email]
    #else:
    #    userid = email
    userid = email
    notify_what = os.getenv("NOTIFY_WHAT")
    hostalias = os.getenv("NOTIFY_HOSTALIAS")
    shortdatetime = os.getenv("NOTIFY_SHORTDATETIME")
    hostaddress = os.getenv("NOTIFY_HOSTADDRESS")
    omdsite = os.getenv("OMD_SITE")
    if notify_what == "SERVICE":
        servicedesc = os.getenv("NOTIFY_SERVICEDESC")
        servicestate = os.getenv("NOTIFY_SERVICESTATE")
        title = "From {}:{} {} is {}".format(omdsite,hostalias,servicedesc,servicestate)
        serviceoutput = os.getenv("NOTIFY_SERVICEOUTPUT")
        longserviceoutput = os.getenv("NOTIFY_LONGSERVICEOUTPUT")
        if not longserviceoutput:
            longserviceoutput = "None"
        description = "<div class=\"gray\">Date:{}</div><div class=\"gray\">IP:{}</div><div class=\"gray\">Message:{}</div><div class=\"gray\">Details:{}</div>".format(shortdatetime,hostaddress,serviceoutput,longserviceoutput)
    else:
        hoststate = os.getenv("NOTIFY_HOSTSTATE")
        hostoutput = os.getenv("NOTIFY_HOSTOUTPUT")
        title = "{} is {}".format(hostalias,hoststate)
        description = "<div class=\"gray\">Date:{}</div><div class=\"gray\">IP:{}</div><div class=\"gray\">Message:{}</div>".format(shortdatetime,hostaddress,hostoutput)

    send_values = {
           "touser" : userid,
           "toparty" : "",
           "msgtype" : "textcard",
           "agentid" : 1000009,
           "textcard" : {
                    "title" : title,
                    "description" : description,
                    "url" : "URL",
                    }
            }

    chat_id = os.getenv("NOTIFY_CONTACTPAGER")
    if chat_id:
        send_url = 'https://qyapi.weixin.qq.com/cgi-bin/appchat/send?access_token=' + access_token
        send_values["chatid"] = chat_id
        send_values["safe"] = 0
        send_values.pop("touser")
        send_values.pop("toparty")
        send_values.pop("agentid")
        
    send_data =  json.dumps(send_values, ensure_ascii=False)
    send_request = urllib2.Request(send_url, send_data)
    response = json.loads(urllib2.urlopen(send_request).read())
#    print response

if __name__ == '__main__':
    corpid = 'XXX'   
    corpsecret = 'XXX'  
    accesstoken = gettoken(corpid,corpsecret)
    senddata(accesstoken)
