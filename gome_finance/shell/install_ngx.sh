#!/bin/bash
#安装nginx: sh install_ngx.sh

install_nginx_path='/data/servers/nginx'
install_package_home='/usr/local/src/openresty_install'
nginx_log_path='/data/logs/nginx'

function install_nginx() {

    #判断系统是否已安装nginx
    if [ -d "${install_nginx_path}" ];then
        echo "已经安装nginx"
    	echo "`date '+%Y%m%d %H:%M:%S'` ERROR:已经安装nginx"
        exit 1
    else
	    mkdir -p ${install_nginx_path}
    fi
    rpm -qa | grep nginx > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo "`date '+%Y%m%d %H:%M:%S'` ERROR:已经安装nginx"
        exit 1
    fi

    cd ${install_package_home}
    nginx_version=`ls ${install_package_home}|grep openresty*.gz|sed 's/\(.*\).tar.gz/\1/g'`
    openssl_version=`ls ${install_package_home}|grep openssl.*gz|sed 's/\(.*\).tar.gz/\1/g'`
    pcre_version=`ls ${install_package_home}|grep pcre.*gz|sed 's/\(.*\).tar.gz/\1/g'`
    zlib_version=`ls ${install_package_home}|grep zlib.*gz|sed 's/\(.*\).tar.gz/\1/g'`
    #安装依赖包
    tar -zxf ${openssl_version}.tar.gz
    tar -zxf ${pcre_version}.tar.gz
    tar -zxf ${zlib_version}.tar.gz
    
    #安装nginx
    tar -zxf ${nginx_version}.tar.gz
    cd ${nginx_version}
    ./configure  --prefix=${install_nginx_path} \
    --sbin-path=${install_nginx_path}/sbin/nginx \
    --conf-path=${install_nginx_path}/conf/nginx.conf \
    --without-http_xss_module \
    --without-http_coolkit_module \
    --without-http_set_misc_module \
    --without-http_form_input_module \
    --without-http_encrypted_session_module \
    --without-http_srcache_module \
    --without-http_headers_more_module \
    --without-http_array_var_module \
    --without-http_memc_module \
    --without-http_redis2_module \
    --without-http_redis_module \
    --without-http_rds_json_module \
    --without-http_rds_csv_module \
    --without-ngx_devel_kit_module \
    --with-http_stub_status_module \
    --with-http_ssl_module \
    --with-http_gzip_static_module \
    --with-luajit \
    --with-pcre=${install_package_home}/${pcre_version} \
    --with-zlib=${install_package_home}/${zlib_version} \
    --with-openssl=${install_package_home}/${openssl_version}
    gmake && gmake install && cd ..
   
    mv ${install_nginx_path}/conf/nginx.conf ${install_nginx_path}/conf/nginx.conf_bak
    cp ${install_package_home}/nginx.conf ${install_nginx_path}/conf/
    mkdir -p ${install_nginx_path}/conf/domains
    cp nginx /etc/init.d/nginx
    chmod +x /etc/init.d/nginx

    if [[ -z `grep 'nginx' /etc/passwd` ]];then
        useradd nginx -u 600 -s /sbin/nologin
    fi

    if [[ -z `grep 'cut_nginxlog' /var/spool/cron/root` ]];then
        echo "1 0 * * * ${install_nginx_path}/sbin/cut_nginxlog.sh" >> /var/spool/cron/root
		mkdir -p ${install_nginx_path}/sbin
        cp cut_nginxlog.sh ${install_nginx_path}/sbin/
        chmod +x ${install_nginx_path}/sbin/cut_nginxlog.sh
    fi

    if [ ! -d "${nginx_log_path}" ];then
        mkdir -p ${nginx_log_path}
    fi
    
    rm -fr ${install_nginx_path}/html/index.html
    chkconfig --add nginx
    chkconfig --level 2345 nginx on
    #service nginx start
    /bin/chown nginx:nginx ${install_nginx_path} -R
    
    #检查安装状态
	/etc/init.d/nginx start
    retval=$?
    if [ $retval -eq 0 ];then
        echo "`date '+%Y%m%d %H:%M:%S'` nginx安装成功"
    else
        echo "`date '+%Y%m%d %H:%M:%S'` nginx安装失败"
        exit 1
    fi

}

#创建目录和下载安装文件
if [ ! -d ${install_package_home} ]; then
    mkdir -p ${install_package_home}
fi
wget -N -P ${install_package_home} http://10.152.4.12/gmy/openresty/openresty-1.11.2.2.tar.gz
wget -N -P ${install_package_home} http://10.152.4.12/gmy/openresty/openssl-1.0.2k.tar.gz
wget -N -P ${install_package_home} http://10.152.4.12/gmy/openresty/pcre-8.40.tar.gz
wget -N -P ${install_package_home} http://10.152.4.12/gmy/openresty/zlib-1.2.11.tar.gz
wget -N -P ${install_package_home} http://10.152.4.12/gmy/openresty/cut_nginxlog.sh
wget -N -P ${install_package_home} http://10.152.4.12/gmy/openresty/nginx
wget -N -P ${install_package_home} http://10.152.4.12/gmy/openresty/nginx.conf
[ ! -d ${nginx_log_path} ] && mkdir -p ${nginx_log_path}

install_nginx

#清理文件
rm -fr ${install_package_home}
