#从nginx制作php镜像
FROM centos_nginx 
MAINTAINER coolbaby
WORKDIR /build/php
ADD . /build/php
EXPOSE 80 8080 9000
COPY run.sh /
RUN /build/php/install_php.sh
WORKDIR /
ENTRYPOINT ["/run.sh"]

