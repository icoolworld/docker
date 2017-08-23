#从centos制作redis镜像
FROM centos_base:latest
MAINTAINER coolbaby
WORKDIR /build/mysql
ADD . /build/mysql
EXPOSE 3306
COPY run.sh /
RUN /build/mysql/install_mysql.sh
WORKDIR /
ENTRYPOINT ["/run.sh"]

