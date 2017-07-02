#从Centos:6.9制作Centos_base镜像
FROM centos:6.9
MAINTAINER coolbaby
ADD . /build/centos_base
WORKDIR /build/centos_base
RUN sh ./install_centos_base.sh
#RUN rm -rf /build/centos_base
WORKDIR /
