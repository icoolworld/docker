#!/bin/bash
# author ljh

#安装wget
#yum -y install wget
#更换yum源,换成aliyun
#wget -O /etc/yum.repos.d/CentOS-Base-aliyun.repo http://mirrors.aliyun.com/repo/Centos-6.repo
mv /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.backup
#mv /etc/yum.repos.d/CentOS-Base-aliyun.repo /etc/yum.repos.d/CentOS-Base.repo
cp source/CentOS-Base-aliyun.repo /etc/yum.repos.d/CentOS-Base.repo

# centos初始化一些环境，安装一些基础的类库等
yum -y install wget curl tar zip unzip xz make gcc git perl perl-ExtUtils-Embed ruby pcre-devel openssl openssl-devel subversion deltarpm;
yum -y install libtool automake autoconf install gcc-c++;
yum -y install libxml2-devel zlib-devel bzip2 bzip2-devel;
yum -y install ncurses-devel readline-devel;
yum -y remove vim vim-enhanced vim-common vim-minimal vim-filesystem;

#timezone set
rm -rf /etc/localtime && ln -s /usr/share/zoneinfo/Asia/Shanghai /etc/localtime

#localedef tools,languages
#yum -y install kde-l10n-Chinese && yum -y reinstall glibc-common
yum -y reinstall glibc glibc-common

#default language set
echo LANG="en_US.UTF-8" >> /etc/sysconfig/i18n
#localedef -c -f UTF-8 -i zh_CN zh_CN.utf
#export LC_ALL zh_CN.utf8
#localedef -c -f UTF-8 -i en_US en_US.utf8
#export LC_ALL en_US.utf8

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
ln -s /usr/local/python2.7.13/bin/python python2

#安装vim8,支持lua,python,perl等,方便其他插件使用代码补全功能
cd ../
tar jxf vim-8.0.tar.bz2
cd vim80/src
#tar zxf vim8.tar.gz
#cd vim/src

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
ln -s /usr/bin/vim /usr/bin/vi

echo "export TERM=xterm-256color" >> /etc/bashrc

cd ../../

#yum切换为python2.6
sed -i "s#/usr/bin/python#/usr/bin/python2.6#g" /usr/bin/yum

#install python pip(requires python version >=2.7.9)
python -m ensurepip
ln -sv /usr/local/python2.7.13/bin/pip /usr/bin/pip
#python -m pip install SomePackage

#install nodejs npm
xz -d node-v6.11.0-linux-x64.tar.xz
tar -xf node-v6.11.0-linux-x64.tar
mv node-v6.11.0-linux-x64 /usr/local/
ln -s /usr/local/node-v6.11.0-linux-x64/bin/node /usr/bin/node
ln -s /usr/local/node-v6.11.0-linux-x64/bin/npm /usr/bin/npm

#install cnpm
npm install -g cnpm --registry=https://registry.npm.taobao.org
#cnpm install [name]
ln -s /usr/local/node-v6.11.0-linux-x64/bin/cnpm /usr/bin/cnpm

# install epel yum
#rpm -ivh http://dl.fedoraproject.org/pub/epel/6/i386/epel-release-6-8.noarch.rpm
#rpm -ivh http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm
rpm -ivh epel-release-6-8.noarch.rpm

cd ../
source ./install_vim_ide.sh
