NagiosPlugins</br>
==================================================</br>
check_mem.sh</br>
功能：内存检测</br>
用法：</br>
1、添加check_mem.sh命令行到nrpe.cfg文件</br>
echo 'command[check_mem]=/usr/local/nagios/libexec/check_mem.sh -w 75 -c 85' >> /usr/local/nagios/etc/nrpe.cfg</br>
2、将php模板拷贝到pnp的目录下：</br>
cp check_mem.php /usr/local/pnp4nagios/share/templates.dist/</br>
</br>
check_net_traffic.sh</br>
功能：网络流量监控</br>
用法：</br>
1、将以下命令行添加到nrpe.cfg</br>
echo 'command[check_net_traffic]=/usr/local/nagios/libexec/check_net_traffic.sh -d eth0 -w 7m -c 10m' >> /usr/local/nagios/etc/nrpe.cfg</br>
参数说明：</br>
-d 是要监控的网卡名</br>
-w -c 是设定的阀值，只能是b、k、m、g，大小写均可，单位是大B（字节），需要说明的是这个阀值是上行（上传）和下行（下载）的总和。</br>
2、将pnp模板考到pnp文件夹：</br>
cp check_net_traffic.sh /usr/local/pnp4nagios/share/templates.dist/</br>
注意：</br>
1、脚本第一次运行时，会将当前网卡的相关数值写到临时文件中，临时文件会保存在/usr/local/nagios/libexec/下。</br>
