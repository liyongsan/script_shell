#Chap 1 安装部署
#Chap 1.1 下载zookeeper
cd /data/servers
wget http://apache.fayea.com/zookeeper/zookeeper-3.4.6/zookeeper-3.4.6.tar.gz
tar xvzf zookeeper-3.4.6.tar.gz
cd /data/servers/zookeeper-3.4.6/conf
#Chap 1.2 修改配置文件
#修改日志路径a
cat log4j.properties 
## Define some default values that can be overridden by system properties
#zookeeper.root.logger=INFO, CONSOLE
#zookeeper.console.threshold=INFO
#zookeeper.log.dir=/data/logs/zookeeper/
#zookeeper.log.file=zookeeper.log
#zookeeper.log.threshold=DEBUG
#zookeeper.tracelog.dir=/data/logs/zookeeper/
#zookeeper.tracelog.file=zookeeper_trace.log
##
## ZooKeeper Logging Configuration
##
## Format is "<default threshold> (, <appender>)+
## DEFAULT: console appender only
#log4j.rootLogger=${zookeeper.root.logger}
## Example with rolling log file
##log4j.rootLogger=DEBUG, CONSOLE, ROLLINGFILE
## Example with rolling log file and tracing
##log4j.rootLogger=TRACE, CONSOLE, ROLLINGFILE, TRACEFILE
##
## Log INFO level and above messages to the console
##
#log4j.appender.CONSOLE=org.apache.log4j.ConsoleAppender
#log4j.appender.CONSOLE.Threshold=${zookeeper.console.threshold}
#log4j.appender.CONSOLE.layout=org.apache.log4j.PatternLayout
#log4j.appender.CONSOLE.layout.ConversionPattern=%d{ISO8601} [myid:%X{myid}] - %-5p [%t:%C{1}@%L] - %m%n
##
## Add ROLLINGFILE to rootLogger to get log file output
##    Log DEBUG level and above messages to a log file
#log4j.appender.ROLLINGFILE=org.apache.log4j.RollingFileAppender
#log4j.appender.ROLLINGFILE.Threshold=${zookeeper.log.threshold}
#log4j.appender.ROLLINGFILE.File=${zookeeper.log.dir}/${zookeeper.log.file}
## Max log file size of 10MB
#log4j.appender.ROLLINGFILE.MaxFileSize=10MB
## uncomment the next line to limit number of backup files
##log4j.appender.ROLLINGFILE.MaxBackupIndex=10
#log4j.appender.ROLLINGFILE.layout=org.apache.log4j.PatternLayout
#log4j.appender.ROLLINGFILE.layout.ConversionPattern=%d{ISO8601} [myid:%X{myid}] - %-5p [%t:%C{1}@%L] - %m%n
##
## Add TRACEFILE to rootLogger to get log file output
##    Log DEBUG level and above messages to a log file
#log4j.appender.TRACEFILE=org.apache.log4j.FileAppender
#log4j.appender.TRACEFILE.Threshold=TRACE
#log4j.appender.TRACEFILE.File=${zookeeper.tracelog.dir}/${zookeeper.tracelog.file}
#log4j.appender.TRACEFILE.layout=org.apache.log4j.PatternLayout
#### Notice we are including log4j's NDC here (%x)
#log4j.appender.TRACEFILE.layout.ConversionPattern=%d{ISO8601} [myid:%X{myid}] - %-5p [%t:%C{1}@%L][%x] - %m%n
cp 2181.cfg 2182.cfg
cp 2181.cfg 2183.cfg
sed -i 's/2181/2182/g' 2182.cfg
sed -i 's/2181/2183/g' 2183.cfg
#创建相关目录
mkdir -p /data/logs/zookeeper/{2181,2182,2183}
mkdir -p /data/file/zookeeper/{2181,2182,2183}
echo 1>/data/file/zookeeper/2181/myid
echo 2>/data/file/zookeeper/2182/myid
echo 3>/data/file/zookeeper/2183/myid
#启动服务
/data/servers/zookeeper-3.4.6/bin/zkServer.sh start /data/servers/zookeeper-3.4.6/conf/2181.cfg 
/data/servers/zookeeper-3.4.6/bin/zkServer.sh start /data/servers/zookeeper-3.4.6/conf/2182.cfg 
/data/servers/zookeeper-3.4.6/bin/zkServer.sh start /data/servers/zookeeper-3.4.6/conf/2183.cfg
#tailf /data/servers/zookeeper-3.4.6/conf/zookeeper.out
