#!/bin/bash
# author ljh
 
# 安装ctags

mkdir -p /data
cd /data

git clone https://github.com/universal-ctags/ctags.git
./autogen.sh
#./configure --prefix=/where/you/want # defaults to /usr/local
./configure 
make
make install # may require extra privileges depending on where to install


## install pip
cd ../
curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py
python get-pip.py

## install node npm

# 安装语法检查器

#jshint js语法检查
#@see http://jshint.com/install/

cnpm install -g jshint
ln -s /usr/local/node-v6.11.0-linux-x64/bin/jshint /usr/bin/jshint

# shell语法检查shellcheck需要先安装cabal
#yum install cabal-rpm.x86_64
#cd syntastic_checker/shellcheck/ShellCheck
#cabal install
#cd ../../../

# python 语法检查flake8 
#@see https://gitlab.com/pycqa/flake8
#@see http://flake8.pycqa.org/en/latest/index.html#quickstart
python -m pip install flake8


# vim配置

cd ../

cp -r ./vimrc/ ~/.vim_runtime
#cat ~/.vim_runtime/vimrcs/basic.vim > /usr/local/vim8/share/vim/vimrc

# 配置vimrc,及安装相关vim插件[代码自动补全,语法检查,查找，目录树，代码注释，区域选择，多行编辑等],打造IDE开发环境
source ./vimrc/install_awesome_vimrc.sh

#清理源文件
rm -rf /build/
