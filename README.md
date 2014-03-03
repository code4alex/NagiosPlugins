NagiosPlugins  
==================================================  
说明：  
1、将相应的检测脚本（*.sh）拷贝到nagios的libexec目录，  
默认路径是: /usr/local/nagios/libexec/  
2、pnp的模板（*.php）拷贝到pnp4nagios的templates.dist目录，  
默认路径是: /usr/local/pnp4nagios/share/templates.dist/  

使用过程中如果有什么问题或者建议可以邮件发送到xiaojun006@163.com,或者QQ5910225。  

check_mem.sh  
功能：  
		内存检测  
用法：  
1、添加自定义命令到nrpe.cfg  
echo 'command[check_mem]=/usr/local/nagios/libexec/check_mem.sh -w 75 -c 85' >> /usr/local/nagios/etc/nrpe.cfg  
  
check_net_traffic.sh  
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
