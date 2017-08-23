#!/bin/bash

BASEDIR=/data/opensource/mysql/
CURDIR=`pwd`

VERSION=5.7.10
LOGFILE=/tmp/install_mysql.log
#mysql本地下载好的相关源码目录,如果没有,将会从官网下载
SOURCEDIR=${CURDIR}/source/
#mysql配置文件,启动脚本目录
MYSQL_CONF_DIR=${CURDIR}/conf/

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


function installMysql()
{
    logToFile "|--> Install Mysql Server..."
    cd ${BASEDIR} 
	#基本类库
	yum -y install tar curl-devel cmake gcc gcc-c++ perl-Data-Dumper libaio git perl bison ncurses-devel
    if [ ! -f mysql-5.7.10-linux-glibc2.5-x86_64.tar.gz ]; then
        if [ -f ${SOURCEDIR}mysql-5.7.10-linux-glibc2.5-x86_64.tar.gz ]; then
            cp ${SOURCEDIR}mysql-5.7.10-linux-glibc2.5-x86_64.tar.gz . >> ${LOGFILE} 2>&1
        else
            wget -c http://dev.mysql.com/get/Downloads/MySQL-5.7/mysql-5.7.10-linux-glibc2.5-x86_64.tar.gz >> ${LOGFILE} 2>&1
        fi
        checkRetval 'download mysql-5.7.10-linux-glibc2.5-x86_64.tar.gz'
    fi

    tar zxf mysql-5.7.10-linux-glibc2.5-x86_64.tar.gz >> ${LOGFILE} 2>&1
	cp -r mysql-5.7.10-linux-glibc2.5-x86_64/ /usr/local/mysql-5.7.10/
    ln -s /usr/local/mysql-5.7.10/ /usr/local/mysql
	cd ..
    checkRetval 'install mysql successfully'
}

function environment()
{
    echo "|--> Mysql environment: "
    groupadd mysql;
    useradd -g mysql -s /bin/false mysql

    cd /usr/local/mysql/
    cp support-files/my-default.cnf /usr/local/mysql/
    cp support-files/mysql.server /etc/init.d/mysql
    chmod +x /etc/init.d/mysql
    chkconfig mysql on

    mkdir -p /home/mysql_log /dev/shm/mysql_tmp /usr/local/mysql/etc
    chown -R mysql.mysql /home/mysql_log /dev/shm/mysql_tmp /usr/local/mysql/etc

    [ -f ${MYSQL_CONF_DIR}my.cnf ] && cp -rf ${MYSQL_CONF_DIR}my.cnf /usr/local/mysql/my.cnf >> ${LOGFILE} 2>&1
    #mysql,mysqladmin等客户端程序默认查找配置文件位置
    #[ -f ${MYSQL_CONF_DIR}my.cnf ] && cp -rf ${MYSQL_CONF_DIR}my.cnf /usr/local/mysql/etc/my.cnf >> ${LOGFILE} 2>&1

    #环境变量
    ln -s /usr/local/mysql/bin/mysql /usr/bin/mysql
    echo 'PATH=$PATH:/usr/local/mysql-5.7.10/bin
export PATH
' >> /etc/profile
    source /etc/profile


    #初始化mysql数据库

    #生成root临时密码
    #bin/mysqld --defaults-file=/usr/local/mysql/my.cnf  --initialize --user=mysql --basedir=/usr/local/mysql --datadir=/usr/local/mysql/data >> ${LOGFILE}
    #不生成root临时密码,需要手动修改密码
    bin/mysqld --defaults-file=/usr/local/mysql/my.cnf --initialize-insecure --user=mysql --basedir=/usr/local/mysql --datadir=/home/mysql_data >> ${LOGFILE}
    
    #InnoDB: Cannot continue operation. ib_logfiles are too small for innodb_thread_concurrency 1000. The combined size    of ib_logfiles should be bigger than 200 kB * innodb_thread_concurrency. 
    #rm -rf /home/mysql_data/ib_logfile*
    /etc/init.d/mysql start
    #/etc/init.d/mysql restart

    #bin/mysql_upgrade -uroot

    #设置root密码
    mysql -uroot -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '123456';"
    #创建mysql帐户work
    mysql -uroot -p123456 -e "CREATE USER 'work'@'localhost' IDENTIFIED BY '123456' PASSWORD EXPIRE NEVER;"
    #创建mywork数据库
    mysql -uroot -p123456 -e "CREATE DATABASE mywork;"
    #创建测试表
    mysql -uroot -p123456 -e "USE mywork;CREATE TABLE pet (name VARCHAR(20), owner VARCHAR(20),species VARCHAR(20), sex CHAR(1), birth DATE, death DATE);"
    #GRANT授权
    mysql -uroot -p123456 -e  "GRANT ALL ON mywork.* TO 'work'@'localhost';"

    cd /
    rm -rf ${BASEDIR} /build/mysql/source

    echo "|--> End Mysql environment: "
}

function main()
{
    installMysql
    environment
}

main
