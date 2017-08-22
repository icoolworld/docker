#!/bin/bash
[ -f /var/run/redis_6379.pid ] && rm -rf /var/run/redis_6379.pid
/etc/init.d/redis_6379 start
/bin/bash
