NagiosPlugins  
==================================================  
##说明：
1、将相应的检测脚本（*.sh）拷贝到nagios的libexec目录(/usr/local/nagios/libexec/)  
2、pnp的模板（*.php）拷贝到pnp4nagios的templates.dist目录(/usr/local/pnp4nagios/share/templates.dist/)  

使用过程中如果有什么问题或者建议可以邮件发送到xiaojun006@163.com,或者QQ5910225。  

##功能介绍:  
###check_mem.sh  
功能：  
		内存检测  
用法：  
1、添加自定义命令到nrpe.cfg  
echo 'command[check_mem]=/usr/local/nagios/libexec/check_mem.sh -w 75 -c 85' >> /usr/local/nagios/etc/nrpe.cfg  
  
效果图：  
![check_mem](/images/check_mem.jpg)  
  
###check_net_traffic.sh  
功能：  
		网络流量监控  
用法：  
1、添加自定义命令到nrpe.cfg  
echo 'command[check_net_traffic]=/usr/local/nagios/libexec/check_net_traffic.sh -d eth0 -w 7m -c 10m' >> /usr/local/nagios/etc/nrpe.cfg  
参数说明：  
-d 是要监控的网卡名  
-w -c 是设定的阀值，只能是b、k、m、g，大小写均可，单位是大B（字节），需要说明的是这个阀值是上行（上传）和下行（下载）的总和。  
注意：  
1、脚本第一次运行时，会将当前网卡的相关数值写到临时文件中，临时文件会保存在/usr/local/nagios/libexec/下。  

效果图：  
![check_net_traffic](/images/check_net_traffic.jpg)  

###check_tcp_stat.sh  
功能：  
		TCP链接状态监测
用法：  
1、将自定义命令添加到nrpe.cfg  
echo 'command[check_tcp_stat]=/usr/local/nagios/libexec/check_tcp_stat.sh -w 300 -c 500 -l' >> /usr/local/nagios/etc/nrpe.cfg  
参数说明：  
-w -c 网络连接数阀值  
-l 开启日志记录功能  
注意：  
1、如开启日志功能，要手动执行一次命令，程序会自动创建/var/log/tcp文件夹。  
日志预览：  
2014-03-03 09:27:49 Total:113 TIME_WAIT:93 ESTABLISHED:20  
2014-03-03 09:30:49 Total:92 TIME_WAIT:72 ESTABLISHED:20  
2014-03-03 09:33:49 Total:132 TIME_WAIT:110 ESTABLISHED:22  
2014-03-03 09:36:49 Total:151 TIME_WAIT:130 FIN_WAIT1:1 ESTABLISHED:20  
2014-03-03 09:39:49 Total:91 TIME_WAIT:70 ESTABLISHED:21  
2014-03-03 09:42:49 Total:84 TIME_WAIT:67 ESTABLISHED:17  
2014-03-03 09:45:49 Total:94 TIME_WAIT:75 FIN_WAIT2:1 ESTABLISHED:18  
2014-03-03 09:48:49 Total:90 TIME_WAIT:69 ESTABLISHED:21  
2014-03-03 09:51:49 Total:101 TIME_WAIT:76 ESTABLISHED:25  
2014-03-03 09:55:54 Total:58 TIME_WAIT:51 ESTABLISHED:7  
  
效果图：  
![tcp stat](/images/tcp_stat.jpg)  

提示信息：  
![tcp stat](/images/tcp_stat_output.jpg)  

