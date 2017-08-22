#!/bin/bash

BASEDIR=/data/opensource/memcached/
CURDIR=`pwd`
VERSION=1.5.0
LOGFILE=/tmp/install_memcache.log
#memcached本地下载好的相关源码目录,如果没有,将会从官网下载
SOURCEDIR=${CURDIR}/source/
#memcached配置文件,启动脚本目录
MEMCACHED_CONF_DIR=${CURDIR}/conf/

[ -f ${LOGFILE} ] && rm -f ${LOGFILE}
[ ! -d ${BASEDIR} ] && mkdir -p ${BASEDIR}

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

function logToFile()
{
    echo $1
    echo "`date +%Y-%m-%d[%T]` $1" >> ${LOGFILE}
}


function installMemcached()
{

    logToFile "|--> Install Memcached Server..."
    cd ${BASEDIR} 
    if [ ! -f libevent-2.1.8-stable.tar.gz ]; then
        if [ -f ${SOURCEDIR}libevent-2.1.8-stable.tar.gz ]; then
            cp ${SOURCEDIR}libevent-2.1.8-stable.tar.gz . >> ${LOGFILE} 2>&1
        else
            wget -c https://github.com/libevent/libevent/releases/download/release-2.1.8-stable/libevent-2.1.8-stable.tar.gz >> ${LOGFILE} 2>&1
        fi
        checkRetval 'download libevent-2.1.8-stable.tar.gz'
    fi

    if [ ! -f memcached-${VERSION}.tar.gz ]; then
        if [ -f ${SOURCEDIR}memcached-${VERSION}.tar.gz ]; then
            cp ${SOURCEDIR}memcached-${VERSION}.tar.gz . >> ${LOGFILE} 2>&1
        else
            wget -c http://www.memcached.org/files/memcached-${VERSION}.tar.gz >> ${LOGFILE} 2>&1
        fi
        checkRetval "download memcached-${VERSION}.tar.gz"
    fi

    tar zxf libevent-2.1.8-stable.tar.gz >> ${LOGFILE} 2>&1
    cd libevent-2.1.8-stable
    ./configure --prefix=/usr/local
    make && make install
    ls -al  /usr/local/lib |grep libevent
    checkRetval 'install libevent successfully'

    cd ../
    tar zxf memcached-${VERSION}.tar.gz >> ${LOGFILE} 2>&1
    cd memcached-${VERSION}
    ./configure --prefix=/usr/local/memcached --with-libevent=/usr/local;
    make; make install
    checkRetval 'install memcached successfully'
}

function environment()
{
    echo "|--> environment: "
    cd ${BASEDIR}
    cp memcached-${VERSION}/scripts/memcached.sysv /etc/init.d/memcached
    sed -i '11 a BINDADDRESS=127.0.0.1' /etc/init.d/memcached
    sed -i 's#daemon memcached#daemon memcached -l $BINDADDRESS#g' /etc/init.d/memcached
    sed -i "s#CACHESIZE=64#CACHESIZE=128#g" /etc/init.d/memcached
    sed -i "s#/var/run/memcached/memcached.pid#/usr/local/memcached/memcached.pid#g" /etc/init.d/memcached
    sed -i "s#/var/run/memcached#/usr/local/memcached/bin/memcached#g" /etc/init.d/memcached
    sed -i "s#daemon memcached#daemon /usr/local/memcached/bin/memcached#g" /etc/init.d/memcached
	chmod +x /etc/init.d/memcached
	chkconfig memcached on
}

function main()
{
    installMemcached
    environment
}

main
