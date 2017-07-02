#!/bin/bash
# author ljh

#安装wget
yum -y install wget
#更换yum源,换成aliyun
wget -O /etc/yum.repos.d/CentOS-Base-aliyun.repo http://mirrors.aliyun.com/repo/Centos-6.repo
mv /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.backup
mv /etc/yum.repos.d/CentOS-Base-aliyun.repo /etc/yum.repos.d/CentOS-Base.repo

# centos初始化一些环境，安装一些基础的类库等
yum -y install wget curl tar zip unzip make gcc git perl perl-ExtUtils-Embed ruby pcre-devel openssl openssl-devel subversion deltarpm;
yum -y install libtool automake autoconf install gcc-c++;
yum -y install libxml2-devel zlib-devel bzip2 bzip2-devel;
yum -y install ncurses-devel readline-devel;
yum -y remove vim vim-enhanced vim-common vim-minimal vim-filesystem;

#进入源码目录
cd source/ 

#安装lua|luajit
tar zxf lua-5.3.4.tar.gz
cd lua-5.3.4
make -j 8 linux test
make -j 8 install INSTALL_TOP=/usr/local/lua5.3.4

mv /usr/bin/lua /usr/bin/lua5.1
mv /usr/bin/luac /usr/bin/luac5.1

ln -s /usr/local/lua5.3.4/bin/lua /usr/bin/lua
ln -s /usr/local/lua5.3.4/bin/luac /usr/bin/luac

#安装luajit
cd ../
tar zxf LuaJIT-2.0.5.tar.gz
cd LuaJIT-2.0.5
make -j 8 && make install PREFIX=/usr/local/luajit2.0.5


#安装python
cd ../
tar zxf Python-2.7.13.tgz
cd Python-2.7.13
./configure --prefix=/usr/local/python2.7.13
make -j 8 && make install

rm -rf /usr/bin/python /usr/bin/python2

ln -s /usr/local/python2.7.13/bin/python /usr/bin/python
#ln -s /usr/local/python2.7.13/bin/python python2

#安装vim8,支持lua,python,perl等,方便其他插件使用代码补全功能
cd ../
tar jxf vim-8.0.tar.bz2
cd vim80/src

./configure --prefix=/usr/local/vim8 --with-features=huge --enable-cscope --enable-rubyinterp --enable-pythoninterp --with-python-config-dir=/usr/local/python2.7.13/lib/python2.7/config --enable-luainterp  --with-lua-prefix=/usr/local/lua5.3.4 --enable-perlinterp --enable-largefile --enable-multibyte --disable-netbeans --enable-cscope >> logs

#./configure --prefix=/usr/local/vim8 \ 
#--with-features=huge \
#--enable-cscope \
#--enable-rubyinterp \
#--enable-pythoninterp \
#--with-python-config-dir=/usr/local/python2.7.13/lib/python2.7/config \
#--enable-luainterp \
#--with-lua-prefix=/usr/local/lua5.3.4 \
#--enable-perlinterp \
#--enable-largefile \
#--enable-multibyte \
#--disable-netbeans \
#--enable-cscope ;\ 
#
make -j 8 && make install

ln -s /usr/local/vim8/bin/vim /usr/bin/vim

# ./configure --prefix=/usr/local/vim8 --with-features=huge --enable-cscope --enable-rubyinterp --enable-pythoninterp --with-python-config-dir=/usr/local/python2.7.13/lib/python2.7/config --enable-luainterp  --with-lua-prefix=/usr/local/lua5.3.4 --enable-perlinterp --enable-largefile --enable-multibyte --disable-netbeans --enable-cscope >> logs