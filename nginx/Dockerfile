#从Centos6.9制作Nginx镜像
FROM centos_base:latest
MAINTAINER coolbaby
WORKDIR /build/nginx
ADD . /build/nginx
EXPOSE 80 80
COPY run.sh /
RUN /build/nginx/install_nginx.sh
RUN /build/nginx/install_nginx_lua.sh
ENTRYPOINT ["/run.sh"]

