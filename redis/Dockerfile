#从centos_base制作redis镜像
FROM centos_base 
MAINTAINER coolbaby
WORKDIR /build/redis
COPY . /build/redis
EXPOSE 6379
COPY run.sh /
RUN /build/redis/install_redis.sh
WORKDIR /
ENTRYPOINT ["/run.sh"]

