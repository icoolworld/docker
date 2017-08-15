#!/bin/bash

. /etc/init.d/functions
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin

#nginx安装日志
LOGFILE=/tmp/install_nginx_lua.log

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
    echo "|--> Download lua package: "

    [ ! -d ${BASEDIR} ] && mkdir -p ${BASEDIR}
    #cd ${BASEDIR}
    if [ ! -f ${BASEDIR}LuaJIT-2.0.5.tar.gz ]; then
        if [ -f ${SOURCEDIR}LuaJIT-2.0.5.tar.gz ]; then
            cp ${SOURCEDIR}LuaJIT-2.0.5.tar.gz ${BASEDIR} >> ${LOGFILE} 2>&1
        else
            wget -c http://luajit.org/download/LuaJIT-2.0.5.tar.gz >> ${LOGFILE} 2>&1
        fi
        checkRetval "download LuaJIT-2.0.5.tar.gz"
    fi

    if [ ! -f ${BASEDIR}ngx_devel_kit.tar.gz ]; then
        if [ -f ${SOURCEDIR}ngx_devel_kit.tar.gz ]; then
            cp ${SOURCEDIR}ngx_devel_kit.tar.gz ${BASEDIR} >> ${LOGFILE} 2>&1
        else
            wget -c https://github.com/simpl/ngx_devel_kit/archive/v0.3.0.tar.gz -O ngx_devel_kit.tar.gz >> ${LOGFILE} 2>&1
        fi
        checkRetval 'download ngx_devel_kit.tar.gz'
    fi
    
    if [ ! -f ${BASEDIR}lua-nginx-module.tar.gz ]; then
        if [ -f ${SOURCEDIR}lua-nginx-module.tar.gz ]; then
            cp ${SOURCEDIR}lua-nginx-module.tar.gz ${BASEDIR} >> ${LOGFILE} 2>&1
        else
            wget -c https://github.com/openresty/lua-nginx-module/archive/v0.10.10.tar.gz -O lua-nginx-module.tar.gz >> ${LOGFILE} 2>&1
        fi
        checkRetval 'download lua-nginx-module.tar.gz'
    fi

    if [ ! -f ${BASEDIR}lua-cjson-2.1.0.tar.gz ]; then
        if [ -f ${SOURCEDIR}lua-cjson-2.1.0.tar.gz ]; then
            cp ${SOURCEDIR}lua-cjson-2.1.0.tar.gz ${BASEDIR} >> ${LOGFILE} 2>&1
        else
            wget -c https://www.kyne.com.au/~mark/software/download/lua-cjson-2.1.0.tar.gz >> ${LOGFILE} 2>&1
        fi
        checkRetval 'download lua-nginx-module.tar.gz'
    fi

    if [ ! -d ${BASEDIR}lua-resty-redis ]; then
        if [ -d ${SOURCEDIR}lua-resty-redis ]; then
            cp -r ${SOURCEDIR}lua-resty-redis ${BASEDIR} >> ${LOGFILE} 2>&1
        else
            git clone https://github.com/openresty/lua-resty-redis.git >> ${LOGFILE} 2>&1
        fi
        checkRetval 'download lua-resty-redis'
    fi
}

function installNginxLua()
{
    echo "|--> Install Nginx: "

    cd ${BASEDIR}

    #安装pcre库
    tar zxf pcre-8.41.tar.gz >> ${LOGFILE} 2>&1
    cd pcre-8.41
    ./configure
    make -j
    make install
    cd ../

    #安装luajit环境
    if [ ! -d /usr/local/luajit2.0.5 ]; then
        tar zxf LuaJIT-2.0.5.tar.gz >> ${LOGFILE} 2>&1
        cd LuaJIT-2.0.5
        make -j && make install PREFIX=/usr/local/luajit2.0.5
        cd ../
    fi

    #导入luajit环境变量
    export LUAJIT_LIB=/usr/local/luajit2.0.5/lib
    export LUAJIT_INC=/usr/local/luajit2.0.5/include/luajit-2.0/

    tar zxf ngx_devel_kit.tar.gz
    tar zxf lua-nginx-module.tar.gz

    cd nginx-${VERSION}
    #lua模块目前不支持OpenSSL 1.1.0+,编译NGINX使用openssl-1.0.2l版本
    ./configure --prefix=/usr/local/nginx-${VERSION} --with-http_stub_status_module --with-http_sub_module --with-http_ssl_module --with-http_v2_module --with-http_gunzip_module --with-stream --with-stream_ssl_module --with-threads --with-file-aio --with-pcre=../pcre-8.41 --with-http_realip_module --with-http_gzip_static_module --with-zlib=../zlib-1.2.11 --with-openssl=../openssl-1.0.2l --with-ld-opt="-lpcre -Wl,-rpath,/usr/local/luajit2.0.5/lib" --add-dynamic-module=../ngx_devel_kit-0.3.0 --add-dynamic-module=../lua-nginx-module-0.10.7
    checkRetval 'configure nginx with lua'

    make modules
    checkRetval 'make'
}


function installLuaPackages()
{
    echo "|--> Install Lua packages: "
    cd ${BASEDIR}

    #lua的cjson包 生成.so
    #生成的.so包，存放在 /usr/local/luajit2.0.5/lib/lua/5.1/
    tar zxf lua-cjson-2.1.0.tar.gz
    cd lua-cjson-2.1.0
    #MAKE FILE
    sed  -i 's#/usr/local$#/usr/local/luajit2.0.5#' Makefile 
    sed -i 's#(PREFIX)/include$#(PREFIX)/include/luajit-2.0#' Makefile
    make && make install
    cd ../
    checkRetval 'make cjson'

    #lua的redis扩展包.lua
    [ ! -d /usr/local/nginx/lua/ ] && mkdir -p /usr/local/nginx/lua/
    cp -r lua-resty-redis /usr/local/nginx/lua/
    checkRetval 'copy lua redis'

    echo "|--> End Install Lua packages"
}

function environment()
{
    echo "|--> environment: "
    #luajit已指定安装路径
    ln -s /usr/local/luajit2.0.5/lib/libluajit-5.1.so.2 /lib64/libluajit-5.1.so.2
    
    #将生成的ngx_lua模块,.so拷到相应的目录
    [ ! -d /usr/local/nginx/modules ] && mkdir -p /usr/local/nginx/modules
    cd ${BASEDIR}nginx-${VERSION}/objs
    cp ndk_http_module.so ngx_http_lua_module.so /usr/local/nginx/modules/
    cp ${NGINX_CONF_DIR}dynamic_module.conf /usr/local/nginx/conf/

    #在nginx.conf配置main环境中调用动态模块(放在开头调用)
    #cat - /usr/local/nginx/conf/nginx.conf < /usr/local/nginx/conf/dynamic_module.conf > /usr/local/nginx/conf/nginx.confbak
    #mv /usr/local/nginx/conf/nginx.confbak /usr/local/nginx/conf/nginx.conf
    sed -i '1 ainclude dynamic_module.conf;' /usr/local/nginx/conf/nginx.conf 

    #在nginx.conf配置http环境调用lua第三方扩展包,如redis,cjson等
    cp ${NGINX_CONF_DIR}/lua_packages.conf /usr/local/nginx/conf/
    sed -i '35 a    include lua_packages.conf;' /usr/local/nginx/conf/nginx.conf 

}

function main()
{
    echo "++ start install nginx with lua++"
    downloadPackage
    installNginxLua
    installLuaPackages
    environment
    echo "++ End Install lua++"
}

# Run main
main

