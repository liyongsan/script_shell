#JDK部署脚本 install_jdk.sh
#使用 install_jdk.sh部署时需要传入JDK的版本参数，如安装jdk1.7需要参数7，安装jdk1.8需要参数8   eg: sh install_jdk.sh [ 7 | 8 ]
#部署安装过程中脚本会自动下载需要版本的JDK包，并将JDK解压到/data/servers/java，并更改系统环境变量；
# 
#脚本内容如下：
#!/bin/bash
#JDK安装 使用方法： sh install_jdk.sh [ 7 | 8 ]
jdk_home='/data/servers/java'
jdk_no=$1
function install() {
if [ ${jdk_no} -eq 7 ]; then
jdk_version="jdk1.7"
elif [ ${jdk_no} -eq 8 ]; then
jdk_version="jdk1.8"
else
echo "请正确输入参数! eg. sh install_jdk.sh [ 7 | 8 ]"
exit 1
fi
[ ! -d ${jdk_home} ] && mkdir -p ${jdk_home}/
wget -N -P ${jdk_home}/ http://10.152.4.12/gmy/tomcat/${jdk_version}.zip
cd ${jdk_home}/ && unzip ${jdk_version}.zip -d ${jdk_home}/ && rm -fr ./${jdk_version}.zip
#设置jdk环境变量
echo "export JAVA_HOME=${jdk_home}/${jdk_version}" >> /etc/profile
echo "export JRE_HOME=${jdk_home}/${jdk_version}/jre" >> /etc/profile
echo 'export CLASSPATH=.:$JAVA_HOME/lib/dt.jar:$JAVA_HOME/lib/tools.jar:$JRE_HOME/lib:$CLASSPATH' >> /etc/profile
echo 'export PATH=$PATH:$JAVA_HOME/bin' >> /etc/profile
source /etc/profile
}
function checkjdk() {
source /etc/profile
java -version 2>&1
if [ $? -eq 0 ]; then
echo "`date '+%Y%m%d %H:%M:%S'` ERROR: JDK Exists,Current Version "`java -version 2>&1 | grep java | awk '{print $3}' | sed 's/\"//g'`
#卸载系统中原有JDK
rpm -qa | grep java
if [ $? -eq 0 ]; then
for i in `rpm -qa | grep java`
do
rpm -e --nodeps $i
done
else
echo '请手动清除当前系统中的JDK后重新运行此脚本安装JDK'
exit 1
fi
else
install
fi
}
function checkresult() {
#检查环境变量
echo $PATH
sleep 3
#检验系统是否已安装JDK成功
echo "JDK install Success. Version: "`java -version 2>&1 | grep java | awk '{print $3}' | sed 's/\"//g'`
}
checkjdk
checkresult
