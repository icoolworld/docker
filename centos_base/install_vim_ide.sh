#!/bin/bash
# author ljh
 
# 安装ctags
cd source;
tar xzvf ctags-5.8.tar.gz
cd ctags-5.8
make distclean;
./configure
make -j && make install;

cd ../

cp -r ./vimrc/ ~/.vim_runtime
#cat ~/.vim_runtime/vimrcs/basic.vim > /usr/local/vim8/share/vim/vimrc

# 配置vimrc,及安装相关vim插件[代码自动补全,语法检查,查找，目录树，代码注释，区域选择，多行编辑等],打造IDE开发环境
source ./vimrc/install_awesome_vimrc.sh
rm -rf /build/

#install syntastic checker 语法检查
#jshint
cnpm install -g jshint
ln -s /usr/local/node-v6.11.0-linux-x64/bin/jshint /usr/bin/jshint
