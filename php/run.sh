#!/bin/bash
echo 'start nginx...'
/usr/local/nginx/sbin/nginx 
echo 'start nginx success...'
echo 'start php-fpm...'
#/usr/local/php/sbin/php-fpm
#service php-fpm start
/etc/init.d/php-fpm start
echo 'start php-fpm success...'
/bin/bash