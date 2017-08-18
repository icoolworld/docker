#!/bin/bash

. /etc/init.d/functions
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin
export LD_LIBRARY_PATH=/usr/local/lib: LD_LIBRARY_PATH

BASEDIR=/data/opensource/php/
CURDIR=`pwd`
VERSION=5.6.22
LOGFILE=/tmp/install_php.log
#php本地下载好的相关源码目录,如果没有,将会从官网下载
SOURCEDIR=${CURDIR}/source/
#php配置文件,启动脚本目录
PHP_CONF_DIR=${CURDIR}/conf/

[ -f ${LOGFILE} ] && rm -f ${LOGFILE}

#开发环境,安装pear,pecl,xdebu等
IS_DEVENV=1

#安装以下php扩展,1-安装,0-不安装
IS_MEMCACHE=1
IS_MEMCACHED=1
IS_REDIS=1
IS_YAF=1
IS_PCNTL=1
IS_SWOOLE=1
IS_OPENSSL=1
IS_MONGO=1

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

function selectInstallItem(){
    read -p "Whether to install Memcache.so  (y/n): " i
    case "$i" in
    'y')
        IS_MEMCACHE=1
    ;;
    'n')
        IS_MEMCACHE=0
    ;;
    *)
        echo "Error: wrong selected" && exit
    ;;
    esac
    
    read -p "Whether to install pcntl.so  (y/n): " i
    case "$i" in
    'y')
        IS_PCNTL=1
    ;;
    'n')
        IS_PCNTL=0
    ;;
    *)
        echo "Error: wrong selected" && exit
    ;;
    esac
}

function installLibmcrypt()
{
    cd ${BASEDIR} 
    logToFile "|--> download depended packages..."
    if [ ! -f libmcrypt-2.5.8.tar.gz ]; then
        if [ -f ${SOURCEDIR}libmcrypt-2.5.8.tar.gz ]; then
            cp ${SOURCEDIR}libmcrypt-2.5.8.tar.gz . >> ${LOGFILE} 2>&1
        else
            wget -c http://downloads.sourceforge.net/project/mcrypt/Libmcrypt/2.5.8/libmcrypt-2.5.8.tar.gz >> ${LOGFILE} 2>&1
        fi
        checkRetval 'download libmcrypt-2.5.8.tar.gz'
    fi
    if [ ! -f mhash-0.9.9.9.tar.gz ]; then
        if [ -f ${SOURCEDIR}mhash-0.9.9.9.tar.gz ]; then
            cp ${SOURCEDIR}mhash-0.9.9.9.tar.gz . >> ${LOGFILE} 2>&1
        else
            wget -c http://downloads.sourceforge.net/project/mhash/mhash/0.9.9.9/mhash-0.9.9.9.tar.gz >> ${LOGFILE} 2>&1
        fi
        checkRetval 'download mhash-0.9.9.9.tar.gz'
    fi
    if [ ! -f mcrypt-2.6.8.tar.gz ]; then
        if [ -f ${SOURCEDIR}mcrypt-2.6.8.tar.gz ]; then
            cp ${SOURCEDIR}mcrypt-2.6.8.tar.gz . >> ${LOGFILE} 2>&1
        else
            wget -c http://downloads.sourceforge.net/project/mcrypt/MCrypt/2.6.8/mcrypt-2.6.8.tar.gz >> ${LOGFILE} 2>&1
        fi
        checkRetval 'download mcrypt-2.6.8.tar.gz'
    fi

    logToFile "|--> install libmcrypt..."
    tar zxf libmcrypt-2.5.8.tar.gz >> ${LOGFILE} 2>&1
    cd libmcrypt-2.5.8
    ./configure >> ${LOGFILE} 2>&1
    make -j 8 >> ${LOGFILE} 2>&1
    make install >> ${LOGFILE} 2>&1
    checkRetval 'libmcrypt'
    cd ../

    logToFile "|--> install mhash..."
    tar zxf mhash-0.9.9.9.tar.gz >> ${LOGFILE} 2>&1
    cd mhash-0.9.9.9
    ./configure >> ${LOGFILE} 2>&1
    make -j 8 >> ${LOGFILE} 2>&1
    make install >> ${LOGFILE} 2>&1
    checkRetval 'mhash'
    cd ..

    logToFile "|--> install mcrypt..."
    tar zxf mcrypt-2.6.8.tar.gz >> ${LOGFILE} 2>&1
    cd mcrypt-2.6.8
    ./configure >> ${LOGFILE} 2>&1
    make -j 8 >> ${LOGFILE} 2>&1
    make install >> ${LOGFILE} 2>&1
    checkRetval 'mcrypt'
    cd ..
}

function installRabbitSo()
{
    cd ${BASEDIR} 
    if [ ! -f simplejson-2.1.1.tar.gz ]; then
        #scp root@10.199.146.42:/data/package/simplejson-2.1.1.tar.gz . >> ${LOGFILE} 2>&1
        checkRetval 'download simplejson-2.1.1.tar.gz'
    fi
    if [ ! -f rabbitmq-c.tar.gz ]; then
        #scp root@10.199.146.42:/data/package/rabbitmq-c.tar.gz . >> ${LOGFILE} 2>&1
        checkRetval 'download rabbitmq-c.tar.gz'
    fi
    if [ ! -f rabbitmq-codegen.tar.gz ]; then
        #scp root@10.199.146.42:/data/package/rabbitmq-codegen.tar.gz . >> ${LOGFILE} 2>&1
        checkRetval 'download rabbitmq-codegen.tar.gz'
    fi

    logToFile "|--> install simplejson..."
    tar zxf simplejson-2.1.1.tar.gz >> ${LOGFILE} 2>&1
    cd simplejson-2.1.1
    python setup.py install >> ${LOGFILE} 2>&1
    checkRetval 'simplejson'
    cd ..

    logToFile "|--> install librabbitmq for rabbit.so ..."
    tar zxf rabbitmq-c.tar.gz >> ${LOGFILE} 2>&1
    tar zxf rabbitmq-codegen.tar.gz >> ${LOGFILE} 2>&1
    mv rabbitmq-codegen-c7c5876a05bb/ rabbitmq-c-ce1eaceaee94/codegen >> ${LOGFILE} 2>&1
    cd rabbitmq-c-ce1eaceaee94 >> ${LOGFILE} 2>&1
    autoreconf -i >> ${LOGFILE} 2>&1
    ./configure >> ${LOGFILE} 2>&1
    make -j 8 >> ${LOGFILE} 2>&1
    [ $? -eq 0 ] && make install >> ${LOGFILE} 2>&1
    checkRetval 'librabbitmq'
}

function installPhp()
{
    logToFile "|--> Install PHP"
    yum --enablerepo=epel -y install gcc gcc-c++ autoconf libjpeg libjpeg-devel libpng libpng-devel freetype freetype-devel libxml2 libxml2-devel zlib zlib-devel glibc glibc-devel glib2 glib2-devel bzip2 bzip2-devel  ncurses ncurses-devel curl curl-devel e2fsprogs e2fsprogs-devel krb5 krb5-devel libidn libidn-devel openssl openssl-devel libtool  libtool-libs libevent-devel libevent openldap openldap-devel nss_ldap openldap-clients openldap-servers libtool-ltdl libtool-ltdl-devel bison libjpeg* libmcrypt  mhash php-mcrypt >> ${LOGFILE} 2>&1
    cd ${BASEDIR} 
    if [ ! -f php-${VERSION}.tgz ]; then
        #scp root@10.199.146.42:/data/package/php-${VERSION}.tgz . >> ${LOGFILE} 2>&1
        checkRetval 'download php-${VERSION}.tgz'
    fi
    tar zxf php-${VERSION}.tgz >> ${LOGFILE} 2>&1
    mv php-${VERSION} ../ >> ${LOGFILE} 2>&1
    cd /usr/local
    ln -s php-${VERSION} php >> ${LOGFILE} 2>&1
    WARN=`/usr/local/php-${VERSION}/bin/php -m|grep "PHP Warning"|wc -l`
    if [ $WARN -gt 0 ];then
        logToFile "PHP extension load error!" && exit 1
    fi
    checkRetval 'PHP installation success'

    cd ${BASEDIR} 
    #scp root@10.199.146.42:/data/package/php-fpm.conf . >> ${LOGFILE} 2>&1
    #scp root@10.199.146.42:/data/package/php.ini . >> ${LOGFILE} 2>&1
    cp php-fpm.conf /usr/local/php-${VERSION}/etc/php-fpm.conf
    cp php.ini /usr/local/php-${VERSION}/etc/php.ini
    mkdir /usr/local/php-${VERSION}/etc/ext
}


function installPhpFromSource()
{
    logToFile "|--> Install PHP From source..."

    logToFile "|--> start yum lib install.."
    yum -y install libxml2 libxml2-devel  bzip2 bzip2-devel curl curl-devel libjpeg libjpeg-devel libpng libpng-devel freetype freetype-devel openssl-devel bison libmcrypt libmcrypt-devel mcrypt mhash libtiff-devel libxslt-devel >> ${LOGFILE} 2>&1
    checkRetval 'yum lib install'
    cd ${BASEDIR} 
    if [ ! -f php-${VERSION}.tar.gz ]; then
        if [ -f ${SOURCEDIR}php-${VERSION}.tar.gz ]; then
            cp ${SOURCEDIR}php-${VERSION}.tar.gz . >> ${LOGFILE} 2>&1
        else
            wget -c http://cn2.php.net/get/php-${VERSION}.tar.gz/from/this/mirror -O php-5.6.22.tar.gz >> ${LOGFILE} 2>&1
        fi
        checkRetval "download php-${VERSION}.tar.gz"
    fi

    tar zxf php-${VERSION}.tar.gz >> ${LOGFILE} 2>&1
    cd php-${VERSION}
    ./configure --prefix=/usr/local/php-${VERSION} --with-config-file-path=/usr/local/php-${VERSION}/etc --enable-fpm --with-openssl --with-pear=/usr/share/php --enable-ftp --enable-zip --with-bz2 --with-zlib --with-libxml-dir=/usr --with-gd --enable-gd-native-ttf --with-jpeg-dir --with-png-dir --with-freetype-dir --with-gettext --with-iconv --enable-mbstring --disable-ipv6 --enable-inline-optimization  --enable-static --enable-sockets --enable-soap --with-mhash --with-pcre-regex --with-mcrypt --with-curl --with-mysql --with-mysqli --with-pdo_mysql >> ${LOGFILE} 2>&1
    checkRetval "./configure"
    make -j 8 >> ${LOGFILE} 2>&1
    [ $? -eq 0 ] && make install >> ${LOGFILE} 2>&1
    checkRetval "make && make install"

    cp /usr/local/php-${VERSION}/etc/php-fpm.conf.default /usr/local/php-${VERSION}/etc/php-fpm.conf
    cp php.ini* /usr/local/php-${VERSION}/etc/
    cp /usr/local/php-${VERSION}/etc/php.ini-development /usr/local/php-${VERSION}/etc/php.ini
    cp sapi/fpm/init.d.php-fpm /etc/rc.d/init.d/php-fpm

    #php-fpm status.html
    sed -i 's#/status#/php-status#' /home/wwwroot/test.com/php-status.html
    cp sapi/fpm/status.html /usr/local/php-${VERSION}/
    cp sapi/fpm/status.html /home/wwwroot/test.com/php-status.html 


    [ -f ${PHP_CONF_DIR}php-fpm.conf ] && cp -rf ${PHP_CONF_DIR}php-fpm.conf /usr/local/php-${VERSION}/etc/php-fpm.conf >> ${LOGFILE} 2>&1
    [ -f ${PHP_CONF_DIR}php.ini ]      && cp -rf ${PHP_CONF_DIR}php.ini /usr/local/php-${VERSION}/etc/php.ini >> ${LOGFILE} 2>&1
    [ -f ${PHP_CONF_DIR}php-fpm ]      && cp -rf ${PHP_CONF_DIR}php-fpm /etc/rc.d/init.d/php-fpm >> ${LOGFILE} 2>&1
    
    chmod +x /etc/init.d/php-fpm
    chkconfig php-fpm on
    

    WARN=`/usr/local/php-${VERSION}/bin/php -m|grep "PHP Warning"|wc -l`
    if [ $WARN -gt 0 ];then
        logToFile "PHP extension load error!" && exit 1
    fi
    checkRetval 'PHP installation success'
    ln -s /usr/local/php-${VERSION}/ /usr/local/php
    ln -s /usr/local/php-${VERSION}/bin/php /usr/bin/php
    mkdir /usr/local/php-${VERSION}/etc/ext
}

function installMemcache()
{
    if [ $IS_MEMCACHE -eq 0 ];then
        return
    fi
    logToFile "|--> Install PHP Extension:Memcache..."
    cd ${BASEDIR} 
    if [ ! -f memcache-2.2.7.tgz ]; then
        if [ -f ${SOURCEDIR}memcache-2.2.7.tgz ]; then
            cp ${SOURCEDIR}memcache-2.2.7.tgz . >> ${LOGFILE} 2>&1
        else
            wget -c http://pecl.php.net/get/memcache-2.2.7.tgz >> ${LOGFILE} 2>&1
        fi
        checkRetval 'download memcache-2.2.7.tgz'
    fi
    tar zxf memcache-2.2.7.tgz >> ${LOGFILE} 2>&1
    cd memcache-2.2.7
    /usr/local/php-${VERSION}/bin/phpize
    ./configure -with-php-config=/usr/local/php-${VERSION}/bin/php-config
    make && make install
    checkRetval 'install php-extension memcache successfully'
    echo '[memcache]
extension=memcache.so
' >> /usr/local/php-${VERSION}/etc/php.ini

}


function installMemcached()
{
    if [ $IS_MEMCACHED -eq 0 ];then
        return
    fi
    logToFile "|--> Install PHP Extension:Memcached..."
    cd ${BASEDIR} 
    if [ ! -f memcached-2.2.0.tgz ]; then
        if [ -f ${SOURCEDIR}memcached-2.2.0.tgz ]; then
            cp ${SOURCEDIR}memcached-2.2.0.tgz . >> ${LOGFILE} 2>&1
        else
            wget -c http://pecl.php.net/get/memcached-2.2.0.tgz >> ${LOGFILE} 2>&1
        fi
        checkRetval 'download memcached-2.2.0.tgz'
    fi

    if [ ! -f libmemcached-1.0.18.tar.gz ]; then
        if [ -f ${SOURCEDIR}libmemcached-1.0.18.tar.gz ]; then
            cp ${SOURCEDIR}libmemcached-1.0.18.tar.gz . >> ${LOGFILE} 2>&1
        else
            wget -c https://launchpad.net/libmemcached/1.0/1.0.18/+download/libmemcached-1.0.18.tar.gz >> ${LOGFILE} 2>&1
        fi
        checkRetval 'libmemcached-1.0.18.tar.gz'
    fi

	tar zxf libmemcached-1.0.18.tar.gz >> ${LOGFILE} 2>&1
	cd libmemcached-1.0.18
	./configure  
    make && make install  
	
	cd ../
	
    tar zxf memcached-2.2.0.tgz >> ${LOGFILE} 2>&1
    cd memcached-2.2.0
    /usr/local/php-${VERSION}/bin/phpize
    ./configure -with-php-config=/usr/local/php-${VERSION}/bin/php-config --enable-memcached --with-libmemcached-dir=/usr/local --disable-memcached-sasl
    make && make install
    checkRetval 'install php-extension memcached successfully'
    echo '[memcached]
extension=memcached.so
' >> /usr/local/php-${VERSION}/etc/php.ini

}

function installYaf()
{
    if [ $IS_YAF -eq 0 ];then
        return
    fi
    logToFile "|--> Install PHP Extension:Yaf..."
    cd ${BASEDIR} 
    if [ ! -f yaf-2.3.5.tgz ]; then
        if [ -f ${SOURCEDIR}yaf-2.3.5.tgz ]; then
            cp ${SOURCEDIR}yaf-2.3.5.tgz . >> ${LOGFILE} 2>&1
        else
            wget -c http://pecl.php.net/get/yaf-2.3.5.tgz >> ${LOGFILE} 2>&1
        fi
        checkRetval 'download yaf-2.3.5.tgz'
    fi
    tar zxf yaf-2.3.5.tgz >> ${LOGFILE} 2>&1
    cd yaf-2.3.5
    /usr/local/php-${VERSION}/bin/phpize
    ./configure -with-php-config=/usr/local/php-${VERSION}/bin/php-config
    make && make install
    checkRetval 'install php-extension yaf successfully'
    echo '[yaf]
extension=yaf.so
yaf.environ=com
;yaf.cache_config=0
yaf.name_suffix=1
;yaf.name_separator=""
;yaf.forward_limit=5
yaf.use_namespace=1
;yaf.use_spl_autoload=0
yaf.lowcase_path=1
' >> /usr/local/php-${VERSION}/etc/php.ini

}

function installRedis()
{
    if [ $IS_REDIS -eq 0 ];then
        return
    fi
    logToFile "|--> Install PHP Extension:Redis..."
    cd ${BASEDIR} 
    if [ ! -f redis-2.2.8.tgz ]; then
        if [ -f ${SOURCEDIR}redis-2.2.8.tgz ]; then
            cp ${SOURCEDIR}redis-2.2.8.tgz . >> ${LOGFILE} 2>&1
        else
            wget -c http://pecl.php.net/get/redis-2.2.8.tgz >> ${LOGFILE} 2>&1
        fi
        checkRetval 'download redis-2.2.8.tgz'
    fi
    tar zxf redis-2.2.8.tgz >> ${LOGFILE} 2>&1
    cd redis-2.2.8
    /usr/local/php-${VERSION}/bin/phpize
    ./configure -with-php-config=/usr/local/php-${VERSION}/bin/php-config
    make && make install
    checkRetval 'install php-extension redis successfully'
    echo '[redis]
extension=redis.so
' >> /usr/local/php-${VERSION}/etc/php.ini

}

function installPcntl()
{
    if [ $IS_PCNTL -eq 0 ];then
        return
    fi
    logToFile "|--> Install PHP Extension:Pcntl..."
    cd ${BASEDIR}php-${VERSION}/ext/pcntl
    /usr/local/php-${VERSION}/bin/phpize
    ./configure -with-php-config=/usr/local/php-${VERSION}/bin/php-config
    make && make install
    checkRetval 'install php-extension pcntl successfully'
    echo '[pcntl]
extension=pcntl.so
' >> /usr/local/php-${VERSION}/etc/php.ini
    logToFile "|--> End Install Pcntl..."
}


function installComposer()
{
    logToFile "|--> Install composer..."
    cd ${BASEDIR}
    if [ ! -f composer.phar ]; then
        if [ -f ${SOURCEDIR}composer.phar ]; then
            cp ${SOURCEDIR}composer.phar . >> ${LOGFILE} 2>&1
        else
            php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
            php -r "if (hash_file('SHA384', 'composer-setup.php') === '669656bab3166a7aff8a7506b8cb2d1c292f042046c5a994c43155c0be6190fa0355160742ab2e1c88d40d5be660b410') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;"
            php composer-setup.php
            php -r "unlink('composer-setup.php');"
            #curl -sS https://getcomposer.org/installer | php >> ${LOGFILE} 2>&1
        fi
        checkRetval 'download composer.phar'
    fi
    chmod +x composer.phar
    cp composer.phar /usr/local/php-${VERSION}/bin/
    cp composer.phar /usr/bin/composer    
    composer
    logToFile "|--> End Install composer..."
}


function installSwoole()
{
    if [ $IS_SWOOLE -eq 0 ];then
        return
    fi
    logToFile "|--> Install PHP Extension:Swoole..."
    cd ${BASEDIR} 
    if [ ! -f swoole-v1.9.18.tar.gz ]; then
        if [ -f ${SOURCEDIR}swoole-v1.9.18.tar.gz ]; then
            cp ${SOURCEDIR}swoole-v1.9.18.tar.gz . >> ${LOGFILE} 2>&1
        else
            wget -c https://github.com/swoole/swoole-src/archive/v1.9.18.tar.gz -O swoole-v1.9.18.tar.gz >> ${LOGFILE} 2>&1
        fi
        checkRetval 'download swoole-v1.9.18.tar.gz'
    fi
    tar zxf swoole-v1.9.18.tar.gz >> ${LOGFILE} 2>&1
    cd swoole-src-1.9.18/
    /usr/local/php-${VERSION}/bin/phpize
    ./configure -with-php-config=/usr/local/php-${VERSION}/bin/php-config
    make -j 8 && make install
    checkRetval 'install php-extension Swoole successfully'
    echo '[swoole]
extension=swoole.so
' >> /usr/local/php-${VERSION}/etc/php.ini
    logToFile "|--> End Install Swoole..."
}

function installMongo()
{
    if [ $IS_MONGO -eq 0 ];then
        return
    fi
    logToFile "|--> Install PHP Extension:Mongo..."
    cd ${BASEDIR} 
    if [ ! -f mongo-1.6.14.tgz ]; then
        if [ -f ${SOURCEDIR}mongo-1.6.14.tgz ]; then
            cp ${SOURCEDIR}mongo-1.6.14.tgz . >> ${LOGFILE} 2>&1
        else
            wget -c http://pecl.php.net/get/mongo-1.6.14.tgz >> ${LOGFILE} 2>&1
        fi
        checkRetval 'download mongo-1.6.14.tgz'
    fi
    tar zxf mongo-1.6.14.tgz >> ${LOGFILE} 2>&1
    cd mongo-1.6.14/
    /usr/local/php-${VERSION}/bin/phpize
    ./configure -with-php-config=/usr/local/php-${VERSION}/bin/php-config
    make -j 8 && make install
    checkRetval 'install php-extension Mongo successfully'
    echo '[mongo]
extension=mongo.so
' >> /usr/local/php-${VERSION}/etc/php.ini
    logToFile "|--> End Install Mongo..."
}

function installXdebug()
{
    logToFile "|--> Install PHP Zend Extension:Xdebug..."
    cd ${BASEDIR} 
    if [ ! -f xdebug-2.5.5.tgz ]; then
        if [ -f ${SOURCEDIR}xdebug-2.5.5.tgz ]; then
            cp ${SOURCEDIR}xdebug-2.5.5.tgz . >> ${LOGFILE} 2>&1
        else
            wget -c https://xdebug.org/files/xdebug-2.5.5.tgz >> ${LOGFILE} 2>&1
        fi
        checkRetval 'download xdebug-2.5.5.tgz'
    fi
    tar zxf xdebug-2.5.5.tgz >> ${LOGFILE} 2>&1
    cd xdebug-2.5.5/
    /usr/local/php-${VERSION}/bin/phpize
    ./configure -with-php-config=/usr/local/php-${VERSION}/bin/php-config --enable-xdebug
    make -j 8 && make install
    checkRetval 'install php-extension Xdebug successfully'
    echo '[xdebug]
zend_extension=xdebug.so
' >> /usr/local/php-${VERSION}/etc/php.ini
    logToFile "|--> End Install Xdebug..."
}

function installPhpcs()
{
    logToFile "|--> Install phpcs..."
    cd ${BASEDIR} 
    if [ ! -f phpcs.phar ]; then
        if [ -f ${SOURCEDIR}phpcs.phar ]; then
            cp ${SOURCEDIR}phpcs.phar . >> ${LOGFILE} 2>&1
        else
            curl -OL https://squizlabs.github.io/PHP_CodeSniffer/phpcs.phar >> ${LOGFILE} 2>&1
        fi
        checkRetval 'download phpcs.phar'
        chmod +x phpcs.phar
        cp phpcs.phar /usr/local/php-${VERSION}/bin/
        cp phpcs.phar /usr/bin/phpcs
        phpcs
    fi
    logToFile "|--> End Install phpcs..."
}

function installPhpPear()
{
    logToFile "|--> Install Pear..."
    cd ${BASEDIR} 
    if [ ! -f go-pear.phar ]; then
        if [ -f ${SOURCEDIR}go-pear.phar ]; then
            cp ${SOURCEDIR}go-pear.phar . >> ${LOGFILE} 2>&1
        else
            wget -c http://pear.php.net/go-pear.phar >> ${LOGFILE} 2>&1
        fi
        checkRetval 'download go-pear.phar'
        /usr/local/php-${VERSION}/bin/php go-pear.phar
        checkRetval 'install go-pear.phar'
        ln -s /usr/local/php-${VERSION}/bin/pear /usr/bin/pear
        ln -s /usr/local/php-${VERSION}/bin/pecl /usr/bin/pecl
    fi
    logToFile "|--> End Install Pear..."
}


function installOpenssl()
{
    if [ $IS_OPENSSL -eq 0 ];then
        return
    fi
    logToFile "|--> Install PHP Extension:openssl..."
    cd ${BASEDIR}php-${VERSION}/ext/openssl
    [ ! -f config.m4 ] && cp config0.m4 config.m4 
    /usr/local/php-${VERSION}/bin/phpize
    ./configure -with-php-config=/usr/local/php-${VERSION}/bin/php-config
    make -j 8 && make install
    checkRetval 'install php-extension openssl successfully'
    echo '[openssl]
extension=openssl.so
' >> /usr/local/php-${VERSION}/etc/php.ini
    logToFile "|--> End Install openssl..."
}

function installPhpUnit()
{
    logToFile "|--> Install PhpUnit..."
    cd ${BASEDIR} 
    if [ ! -f phpunit-5.7.phar ]; then
        if [ -f ${SOURCEDIR}phpunit-5.7.phar ]; then
            cp ${SOURCEDIR}phpunit-5.7.phar . >> ${LOGFILE} 2>&1
        else
            wget -c https://phar.phpunit.de/phpunit-5.7.phar >> ${LOGFILE} 2>&1
        fi
        checkRetval 'download phpunit.phar'
        chmod +x phpunit-5.7.phar
        cp phpunit-5.7.phar /usr/local/php-${VERSION}/bin/
        cp phpunit-5.7.phar /usr/bin/phpunit
        #phpunit
        checkRetval 'install phpunit.phar'
    fi
    logToFile "|--> End Install PhpUnit..."
}


function main()
{
    pkill php-fpm
    rm -rf ${BASEDIR}/*
    rm -rf /usr/local/php
    rm -rf /usr/local/php-${VERSION}
    [ ! -d ${BASEDIR} ] && mkdir -p ${BASEDIR}
    logToFile  "++ Start Install PHP ++"
    #selectInstallItem
    #installRabbitSo
    #installPhp
    installLibmcrypt
    installPhpFromSource
    installMemcache
    installMemcached
    installRedis
    installYaf
    installComposer
    installPcntl
    installSwoole
    installOpenssl
    installMongo
    if [ $IS_DEVENV -eq 1 ];then
        installPhpcs
        installPhpUnit
        installXdebug
        installPhpPear
    fi
    service php-fpm start
    #/usr/local/php-${VERSION}/sbin/php-fpm
    #lsof -i:9000 | wc -l
    logToFile  "++ End Install PHP ++"
}

main
