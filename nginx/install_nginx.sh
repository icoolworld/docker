#!/bin/bash

. /etc/init.d/functions
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin

#nginx安装日志
LOGFILE=/tmp/install_nginx.log

#nginx版本
VERSION=1.10.1

#nginx相关源码目录,如果没有,将会从官网下载
SOURCEDIR=`pwd`/source/

#源码下载后存储目录
BASEDIR=/data/opensource/nginx/

#nginx配置文件,启动脚本存放目录
NGINX_CONF_DIR=`pwd`/conf/

function checkRetval()
{
    val=$?
    echo -n $"$1"
    if [ $val -ne 0 ]
    then
            failure
            echo
            exit 1
    fi
    success
    echo
}

function logToFile() {
        echo $1
        echo "`date +%Y-%m-%d[%T]` $1" >> ${LOGFILE}
}

function downloadPackage()
{
    echo "|--> Download package: "

    [ ! -d ${BASEDIR} ] && mkdir -p ${BASEDIR}
    #cd ${BASEDIR}
    if [ ! -f ${BASEDIR}nginx-${VERSION}.tar.gz ]; then
        if [ -f ${SOURCEDIR}nginx-${VERSION}.tar.gz ]; then
            cp ${SOURCEDIR}nginx-${VERSION}.tar.gz ${BASEDIR} >> ${LOGFILE} 2>&1
        else
            wget -c http://nginx.org/download/nginx-${VERSION}.tar.gz >> ${LOGFILE} 2>&1
        fi
        checkRetval "download nginx-${VERSION}.tar.gz"
    fi

    if [ ! -f ${BASEDIR}pcre-8.41.tar.gz ]; then
        if [ -f ${SOURCEDIR}pcre-8.41.tar.gz ]; then
            cp ${SOURCEDIR}pcre-8.41.tar.gz ${BASEDIR} >> ${LOGFILE} 2>&1
        else
            wget -c ftp://ftp.csx.cam.ac.uk/pub/software/programming/pcre/pcre-8.41.tar.gz >> ${LOGFILE} 2>&1
        fi
        checkRetval 'download pcre-8.41.tar.gz'
    fi
    
    if [ ! -f ${BASEDIR}zlib-1.2.11.tar.gz ]; then
        if [ -f ${SOURCEDIR}zlib-1.2.11.tar.gz ]; then
            cp ${SOURCEDIR}zlib-1.2.11.tar.gz ${BASEDIR} >> ${LOGFILE} 2>&1
        else
            wget -c http://zlib.net/zlib-1.2.11.tar.gz >> ${LOGFILE} 2>&1
        fi
        checkRetval 'download zlib-1.2.11.tar.gz'
    fi
    
    #nginx的lua模块暂时不支持1.1.0+的openssl
    #
    # if [ ! -f ${BASEDIR}openssl-1.1.0f.tar.gz ]; then
    #     if [ -f ${SOURCEDIR}openssl-1.1.0f.tar.gz ]; then
    #         cp ${SOURCEDIR}openssl-1.1.0f.tar.gz ${BASEDIR} >> ${LOGFILE} 2>&1
    #     else
    #         wget -c https://www.openssl.org/source/openssl-1.1.0f.tar.gz >> ${LOGFILE} 2>&1
    #     fi
    #     checkRetval 'download openssl-1.1.0f.tar.gz'
    # fi

    if [ ! -f ${BASEDIR}openssl-1.0.2l.tar.gz ]; then
        if [ -f ${SOURCEDIR}openssl-1.0.2l.tar.gz ]; then
            cp ${SOURCEDIR}openssl-1.0.2l.tar.gz ${BASEDIR} >> ${LOGFILE} 2>&1
        else
            wget -c https://www.openssl.org/source/openssl-1.0.2l.tar.gz >> ${LOGFILE} 2>&1
        fi
        checkRetval 'download openssl-1.0.2l.tar.gz'
    fi

}

function installNginx()
{
    echo "|--> Install Nginx: "
    #基础类库
    yum -y install wget curl tar make gcc perl pcre-devel openssl-devel libxml2-devel zlib-devel bzip2-devel
    cd ${BASEDIR}
    tar zxf nginx-${VERSION}.tar.gz >> ${LOGFILE} 2>&1

    tar zxf pcre-8.41.tar.gz
    #cd pcre-8.41
    #./configure
    #make -j
    #make install

    tar zxf zlib-1.2.11.tar.gz
    #cd ../zlib-1.2.11
    #./configure
    #make
    #make install

    #tar zxf openssl-1.1.0f.tar.gz
    #cd ../openssl-1.1.0f
    #./configure --prefix=/usr
    #make
    #make install
    
    tar zxf openssl-1.0.2l.tar.gz

    #cd ../
    cd nginx-${VERSION}

    # Mark debug mode
    #sed -i 's/CFLAGS="$CFLAGS -g"/\#CFLAGS="$CFLAGS -g"/g' auto/cc/gcc >> ${LOGFILE} 2>&1
    # Hide nginx version
    #sed -i -e "s/${VERSION}/2.2/g" -e 's/nginx\//Apache\//g' src/core/nginx.h >> ${LOGFILE} 2>&1

    #编译第三方模块,静态编译
    #./configure ... --add-module=/usr/build/nginx-rtmp-module
    #编译第三方模块,动态编译,生成.so文件
    #./configure ... --add-dynamic-module=/path/to/module
    #常用编译选项
    #./configure --prefix=/usr/local/nginx-${VERSION} --with-http_stub_status_module --with-http_sub_module --with-http_ssl_module --with-pcre=../pcre-8.41 --with-http_realip_module --with-http_gzip_static_module --with-zlib=../zlib-1.2.11 --with-openssl=../openssl-1.1.0f
    #编译常用选项,ssl支持,http2,TCP代理支持等
    ./configure --prefix=/usr/local/nginx-${VERSION} --with-http_stub_status_module --with-http_sub_module --with-http_ssl_module --with-http_v2_module --with-http_gunzip_module --with-stream --with-stream_ssl_module --with-threads --with-file-aio --with-pcre=../pcre-8.41 --with-http_realip_module --with-http_gzip_static_module --with-zlib=../zlib-1.2.11 --with-openssl=../openssl-1.0.2l
    checkRetval 'configure'
    make -j 8 >> ${LOGFILE} 2>&1
    checkRetval 'make'
    make install >> ${LOGFILE} 2>&1
    checkRetval 'make install'
    ln -s /usr/local/nginx-${VERSION} /usr/local/nginx
}

function environment()
{
    echo "|--> environment: "
    [ ! -d /home/wwwroot ] && mkdir -p /home/wwwroot
    [ ! -d /home/httplogs ] && mkdir -p /home/httplogs

    #cd ${BASEDIR}
    cp ${NGINX_CONF_DIR}nginx.conf ${BASEDIR} >> ${LOGFILE} 2>&1
    cp ${NGINX_CONF_DIR}default_server.conf ${NGINX_CONF_DIR}lua_server.conf ${BASEDIR} >> ${LOGFILE} 2>&1
    cp ${NGINX_CONF_DIR}nginx ${BASEDIR} >> ${LOGFILE} 2>&1
    cp ${NGINX_CONF_DIR}fastcgi_cache.conf ${BASEDIR} >> ${LOGFILE} 2>&1

    cd ${BASEDIR}
    cp nginx /etc/init.d/nginx
    chmod +x /etc/init.d/nginx
    /sbin/chkconfig --add nginx
    chkconfig nginx on
    checkRetval '/etc/init.d/nginx'

    mv /usr/local/nginx/conf/nginx.conf /usr/local/nginx/conf/nginx.conf.bak
    #nginx.conf主配置
    cp nginx.conf fastcgi_cache.conf /usr/local/nginx/conf/
    #虚拟主机server
    mkdir -p /usr/local/nginx/conf/vhosts
    cp default_server.conf lua_server.conf /usr/local/nginx/conf/vhosts/

    mkdir /home/wwwroot/test.com/
    echo "<?php phpinfo(); ?>" > /home/wwwroot/test.com/phpinfo.php
    echo "hello~" > /home/wwwroot/test.com/index.html
    chown -R nobody.nobody /home/wwwroot/test.com
    checkRetval 'copy complete'
}

# Run main
function main()
{
    pkill nginx
    rm -rf /etc/init.d/nginx
    rm -rf ${BASEDIR}*
    rm -rf /usr/local/nginx
    rm -rf /usr/local/nginx-${VERSION}

    [ -f ${LOGFILE} ] && rm -f ${LOGFILE}
    echo "++ start install nginx ++"
    downloadPackage
    installNginx
    environment

    /etc/init.d/nginx start
    #lsof -i:80

    HOST=`hostname -i`
    echo "Look: http://${HOST}:80/index.html"
    echo "Look: http://${HOST}:80/phpinfo.php"

    echo "++ End Install ++"
}


main

