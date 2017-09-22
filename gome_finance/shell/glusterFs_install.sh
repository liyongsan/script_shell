#!/bin/bash
yum -y install flex fuse bison openssl openssl-devel xfsprogs \
aclocal autoconf aotuheader automake libtool automake autoconf \
libtool flex bison libxml2-devel python-devel libaio-devel libibverbs-devel \
librdmacm-devel readline-devel lvm2-devel glib2-devel userspace-rcu-devel libcmocka-devel
wget -N -P /etc/yum.repos.d http://10.152.4.12/gmy/glusterfs/CentOS-Gluster-3.8.repo
yum clean all
yum install glusterfs-server-3.8.10 -y
/etc/init.d/glusterd restart
if [ $? -eq 0 ]; then
echo 'GluaterFS3.8.10安装成功！'
else 
echo 'GluaterFS3.8.10安装失败！'
exit 1
fi
#Client端说明如下：
#GlusterFS客户端配置说明：
#1、wget http://standard.gmfcloud.com/gmy/glusterfs/install-glusterfs-client.sh
 #                                                  GlusterFS卷名  挂载点       server1           server2        servername01             servername02
                                                                          (自定义)
#2、sh -x install-glusterfs-client.sh db-backup  /glusterfs/  10.152.3.211 10.152.3.212 ops-dbglusterfs-3-211 ops-dbglusterfs-3-212
#Glusterfs-Client端安装配置脚本如下：
#!/bin/bash
wget -N -P /etc/yum.repos.d http://10.152.4.12/gmy/glusterfs/CentOS-Gluster-3.8.repo
yum clean all
yum makecache
yum install glusterfs glusterfs-fuse glusterfs-rdma -y
modprobe fuse
lsmod |grep fuse
#Client端挂载点的读写监控脚本如下：（执行脚本需带参数：GlusterFS的Server信息）
#!/bin/bash
Volume_Name=$1
dir=$2
ip1=$3
ip2=$4
Host1=$5
Host2=$6
Install(){
#wget -N -P /etc/yum.repos.d http://standard.gmfcloud.com/gmy/glusterfs/CentOS-Gluster-3.8.repo
rpm -ivh http://10.143.50.201/Files/rpmbuild/gomerepo-1.0.0-1.x86_64.rpm
gomerepo init
yum clean all
#yum makecache
yum install glusterfs-client-xlators-3.8.10 glusterfs-fuse-3.8.10 glusterfs-rdma-3.8.10 glusterfs-libs-3.8.10 -y
modprobe fuse
lsmod |grep fuse
rpm -qa | grep glusterfs
if [ $? -eq 0 ];then
{
echo 'GlusterFS-3.8.10 Client Installation has been Successfull.'
}
else
{
echo 'GlusterFS-3.8.10 Client Installation Failed.'
}
fi
}
Update_hosts(){
grep -E "$Host2|$Host1" /etc/hosts 2>&1 >/dev/null
if [ `echo $?` -ne 0 ];then
echo "$ip1 $Host1" >> /etc/hosts
echo "$ip2 $Host2" >> /etc/hosts
else
echo '主机配置已存在'
fi
}
rpm -qa | grep glusterfs
if [[ $? -eq 0 ]];then
{
yum remove -y glusterfs* glusterfs-client-xlators* glusterfs-libs* glusterfs-fuse* glusterfs-rdma*
Install
Update_hosts
}
else
{
Install
Update_hosts
}
fi
mkdir -p /$dir
if [ $? -eq 0 ];then
{
echo "mount -t glusterfs $Host1:$Volume_Name $dir" >> /etc/rc.d/rc.local
mount -t glusterfs $Host1:$Volume_Name $dir
}
else
{
echo "$dir has been Exist."
}
fi
