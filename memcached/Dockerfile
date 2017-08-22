#从nginx制作memcache镜像
FROM centos_base 
MAINTAINER coolbaby
WORKDIR /build/memcached
COPY . /build/memcached
EXPOSE 11211
COPY run.sh /
RUN /build/memcached/install_memcached.sh
WORKDIR /
ENTRYPOINT ["/run.sh"]

