#从Centos6.7制作Nginx镜像
FROM centos:latest
MAINTAINER coolbaby
ADD . /build/centos_base
COPY functions /etc/init.d/functions
WORKDIR /build/centos_base
RUN sh ./install_centos_base.sh
#RUN rm -rf /build
WORKDIR /
