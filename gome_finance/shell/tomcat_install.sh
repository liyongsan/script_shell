#使用 install_tomcat.sh部署时需要传入tomcat的版本参数 | Tomcat的端口号 | APP name，如安装Tomcat7需要参数7，安装Tomcat8需要参数8  
# eg: sh install_tomcat.sh 参数1:[7|8] 参数2:[tomcatport:8001-9090] 参数3:[app_name]
#部署安装过程中脚本会自动下载需要版本的Tomcat安装包和相关配置文件，并将Tomcat安装到/data/servers/tomcat_[tomcatport]，并将jmxremote port修改为 1[tomcatport]
#将 shutdown prot修改为2[tomcatport]；
#*注意* 部署完成后脚本会默认使用root去启动tomcat检测是否安装成功，请在实际部署中根据具体业务需求使用对应用户启动tomcat服务；
# 
#脚本内容如下：
 
#!/bin/sh
#install tomcat
#脚本参数说明 sh install_tomcat.sh 参数1:[7|8] 参数2:[tomcatport:8001-9090] 参数3:[app_name]
[[ $# -ne 3 ]] && echo -e "输入参数个数有误\n脚本参数说明 sh install_tomcat.sh\n参数1:[7|8]\n参数2:[tomcatport:8001-9090]\n参数3:[app_name]" && exit 1
[[ $2 -lt 8001 ]] || [[ $2 -gt 9090 ]] && echo -e "输入第2个参数值有误\n脚本参数说明 sh install_tomcat.sh \n参数1:[7|8]\n参数2:[tomcatport:8001-9090]\n参数3:[app_name]" && exit 1
if [[ $1 -eq 7 ]];then
tomcat_version=tomcat_7
elif [[ $1 -eq 8 ]];then
tomcat_version=tomcat_8
else
echo -e "输入第1个参数值有误\n脚本参数说明 sh install_tomcat.sh \n参数1:[7|8]\n参数2:[tomcatport:8001-9090]\n参数3:[app_name]"
exit 1
fi
tomcat_port=$2
jmx_port=1$2
shut_port=2$2
app_name=$3
tomcat_home="/data/servers/tomcat_${app_name}_${tomcat_port}"
install_package_home='/data/public/soft/tomcat'
app_home="/data/app/${app_name}"
#判断tomcat是否安装
if [ -d "${tomcat_home}" ];then
# echo "已安装tomcat_${tomcat_port}"
echo "`date '+%Y%m%d %H:%M:%S'` ERROR:已经安装tomcat_${tomcat_port}"
exit 1 
fi
netstat -lntp |awk '{print $4}'|cut -d: -f2|grep "${tomcat_port}" > /dev/null 2>&1
if [ $? -eq 0 ]; then
echo "`date '+%Y%m%d %H:%M:%S'` ERROR:端口冲突，请重新输入参数"
exit 1
fi
#创建路径
if [ ! -d /data/servers ];then
mkdir -p /data/servers
fi
if [ ! -d /data/app/${app_name} ];then
mkdir -p /data/app/${app_name}
fi
if [ ! -d ${install_package_home} ];then
mkdir -p ${install_package_home}
fi
#安装tomcat
wget -N -P ${install_package_home} http://10.152.4.12/gmy/tomcat/${tomcat_version}.zip
if [ $? -ne 0]; then
echo '下载安装包失败' 
exit 1
fi
wget -N -P ${install_package_home} http://10.152.4.12/gmy/tomcat/tomcat_8080
cd ${install_package_home}
if [ $? -ne 0]; then
echo '下载安装包失败'
exit 1
fi
unzip ${tomcat_version}.zip
mv ${tomcat_version} ${tomcat_home}
rm -fr ${tomcat_home}/webapps/*
sed -i "s/8001/${tomcat_port}/g" ${tomcat_home}/conf/server.xml
sed -i "s/9001/${shut_port}/g" ${tomcat_home}/conf/server.xml
sed -i "s/space/${app_name}/g" ${tomcat_home}/conf/Catalina/localhost/ROOT.xml
sed -i "s/1600/${jmx_port}/g" ${tomcat_home}/bin/catalina.sh
chmod +x ${tomcat_home}/bin/*.sh
sed -i "s/app/${app_name}/g" ${install_package_home}/tomcat_8080
sed -i "s/8080/${tomcat_port}/g" ${install_package_home}/tomcat_8080
cp -r -f ${install_package_home}/tomcat_8080 /etc/init.d/tomcat_${app_name}_${tomcat_port}
chmod +x /etc/init.d/tomcat_${app_name}_${tomcat_port}
chkconfig --level 2345 tomcat_${app_name}_${tomcat_port} on
/etc/init.d/tomcat_${app_name}_${tomcat_port} start
retval=$?
if [ $retval -eq 0 ];then
echo "`date '+%Y%m%d %H:%M:%S'` tomcat安装成功"
else
echo "`date '+%Y%m%d %H:%M:%S'` tomcat安装失败"
exit 1
fi
#清理安装文件
rm -fr ${install_package_home}
