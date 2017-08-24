#!/bin/bash

#get enviroment variable
. /etc/profile

version=3.2.8
install_dir=/data/database/install
server_dir=/data/database/redis/$2
bin_dir=$server_dir/bin
data_dir=$server_dir/data
log_dir=$server_dir/logs
pid_dir=$server_dir/pid
conf_dir=$server_dir/conf
agent_dir=`pwd`

pre_install() {
yum install gcc gcc-c++ glibc wget tcl -y
        cd $install_dir
        if [ ! -e redis-$version.tar.gz ]
        then
                echo "Getting redis package by wget, waiting ..."
                if ! wget -O redis-$version.tar.gz "https://codeload.github.com/antirez/redis/tar.gz/$version"
                then
                        echo >&2 "Can't get redis package from adm.cache.jd.local, try adm.cache.jd.com!"
                        /bin/rm -fr redis-$version.tar.gz

                    if ! wget http://adm.cache.jd.com/static/redis-$version.tar.gz
                    then
                            echo >&2 "Can't get redis package, exit!"
                            /bin/rm -fr redis-$version.tar.gz
                            exit 1
                    fi
                fi
        fi
}

install() {
        if ! pre_install
        then
                echo >&2 "Not suitable to install, exit!"
                exit 1
        fi
	cd $install_dir && tar xzvf redis-$version.tar.gz
	rm $install_dir/redis-$version.tar.gz -f
        cd $install_dir/redis-$version && make
	echo "Done."	
}

check_port() {
	echo "Checking instance port ..."
	netstat -tlpn | grep "\b$1\b"

}

#check and prepare the condition needed to deploy
prepare_deploy() {
	if [ $# -gt 0 ]
	then
		port=$1
	fi

	if [ -z $port ]
	then
		echo >&2 "you must provide redis instance port, exit!"
		exit 1
	fi

	if check_port $port
	then
		echo >&2 "$port port is using, exit!"
		exit 1
	fi	

	if [ ! -x $install_dir/redis-$version/src/redis-cli ]
	 then 
		echo echo "No redis install on this machine. Skipped."	
		exit 1
	fi
	mkdir -p $bin_dir $server_dir $data_dir $log_dir $pid_dir $conf_dir
}

deploy() {
	if ! prepare_deploy $@
	then
		echo >&2 "Not suitable to deploy, exit!"
		exit 1
	fi
	echo "Deploying redis instance $version ..."
    if [  -z $version ]
	then
		echo "version is empty!!"
	else
        case $version in
        2.8.23)
                shift
                cp $install_dir/redis-$version/src/{mkreleasehdr.sh,redis-benchmark,redis-check-aof,redis-check-dump,redis-cli,redis-sentinel,redis-server} $bin_dir/
                ;;
        2.8.24)
                shift
                cp $install_dir/redis-$version/src/{mkreleasehdr.sh,redis-benchmark,redis-check-aof,redis-check-dump,redis-cli,redis-sentinel,redis-server} $bin_dir/
                ;;
        3.0.7)
                shift
                cp $install_dir/redis-$version/src/{mkreleasehdr.sh,redis-benchmark,redis-check-aof,redis-check-dump,redis-cli,redis-sentinel,redis-server,redis-trib.rb} $bin_dir/
                ;;
        3.2.8)
                shift
                cp $install_dir/redis-$version/src/{mkreleasehdr.sh,redis-benchmark,redis-check-aof,redis-check-rdb,redis-cli,redis-sentinel,redis-server,redis-trib.rb} $bin_dir/ 
                ;;
        			*)
         echo "version is not support!!"      
                ;;
        esac
    fi
        cp $install_dir/redis.conf.$version $conf_dir/redis_$port.conf
        cd $conf_dir
	sed -i "s:\${port}:${port}:g; s:\${data_dir}:${data_dir//\//\/}:g; s:\${log_dir}:${log_dir//\//\/}:g; s:\${pid_dir}:${pid_dir//\//\/}:g" redis_$port.conf
	sed -i "s/re_port/$port/g" redis_$port.conf
}

start() {
	[ $# -ne 1 ] && echo "Instance port must be provided!" && exit 1
	pid=`netstat -ntlp | grep -w $1 | head -1 | awk '{print $7}' | cut -d '/' -f1`
	if [ -z $pid ]
	then
		if [ -z $bin_dir ]
		then
				echo "No redis install on this machine. Skipped."
		else
			$bin_dir/redis-server $conf_dir/redis_$1.conf
		fi
		echo "Done."
	else
		echo "There is already one instance running at $1 port. Skip!"
	fi
}

restart() {
	[ $# -ne 1 ] && echo "Instance port must be provided!" && exit 1
	pid=`netstat -ntlp | grep -w $1 | head -1 | awk '{print $7}' | cut -d '/' -f1`
	if [ -z $pid ]
	then
		echo "There is no instance running at $1 port."
	else
		cd `ls -l /proc/$pid/exe | sed 's/.*\s//;s/redis-server//'` && cd ..
		redis_dir=`pwd`
		if [ -e $redis_dir/bin/redis-server ]
		then
			if [ -e $redis_dir/bin/redis-cli ]
			then
				PassWORD=`cat $redis_dir/conf/redis_$1.conf | grep requirepass | grep -v configuration | awk '{print $2}'`
				$redis_dir/bin/redis-cli -p $1 -a $PassWORD shutdown save
				if [ $? -ne 0 ] 
				then
					kill -s TERM $pid
				fi
			else
				kill -s TERM $pid
			fi
			sleep 2
			$redis_dir/bin/redis-server $redis_dir/conf/redis_$1.conf
			echo "Done."
		fi
	fi
}

stop() {
	[ $# -ne 1 ] && echo "Instance port must be provided!" && exit 1
	pid=`netstat -ntlp | grep -w $1 | head -1 | awk '{print $7}' | cut -d '/' -f1`
	if [ -z $pid ]
	then
		echo "There is no instance running at $1 port. Stopped already."
	else
                cd `ls -l /proc/$pid/exe | sed 's/.*\s//;s/redis-server//'` && cd ..
                redis_dir=`pwd`
                        if [ -e $redis_dir/bin/redis-cli ]
                        then
        			PassWORD=`cat $redis_dir/conf/redis_$1.conf | grep requirepass | grep -v configuration | awk '{print $2}'`
                                $redis_dir/bin/redis-cli -p $1 -a $PassWORD shutdown save
				if [ $? -ne 0 ] 
				then
					echo "This instance can't be shutdown by command, forced to close!"
					kill -s TERM $pid
				fi
			else
				echo "This instance wasn't deployed in normal, forced to close!"
				kill -s TERM $pid
			fi
		echo "Done."
	fi
}

status() {
	[ $# -ne 1 ] && echo "Instance port must be provided!" && exit 1
	if [ -z `netstat -ntlp | grep -w $1 | head -1 | awk '{print $7}' | cut -d '/' -f1` ]
	then
		echo "Stopped!"
	else
		echo "Running..."
	fi
}

list() {
	for item in `ps -ef | grep 'redis-server' | awk '{print $8"|"$9}' | grep -v '^grep'`
	do
		local redis_server_path=${item%|*}
		local conf=${item#*|}
		if echo $conf | grep -q -E ':[0-9]+$'
		then
			port=`echo $conf |awk -F':' '{print $NF}'`
			conf1=`echo $redis_server_path | sed -e "s:bin/redis-server:conf/redis_$port.conf:"`
		else
			port=`echo ${conf##/*/} | grep -o -E '[0-9]+$'`
		fi
		echo "$port  $redis_server_path  $conf1"
	done
}

help() {
	echo "Usage: ./`basename $0` {restart|start|stop|status|install|list|deploy} PORT"
}

if [ $# -eq 0 ]
then
	help
else
	case $1 in
        install)
                shift
                install 
                ;;
	deploy)
		shift
		if deploy $@
		then
			start $port
		fi
		;;
	start)
		shift
		start $@
		;;
	restart)
		shift
		restart $@
		;;
	stop)
		shift
		stop $@
		;;
	status)
		shift
		status $@
		;;
	list)
		list
		;;
	*|-h|--help)
		help
		;;
	esac
fi

exit 0


