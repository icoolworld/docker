#!/bin/bash
#service mysql start
echo 'start mysql...'
[ ! -d /dev/shm/mysql_tmp ] && mkdir -p /dev/shm/mysql_tmp && chown -R mysql.mysql /dev/shm/mysql_tmp
/etc/init.d/mysql start
if [ $? -eq 0 ]; then
    echo 'start mysql successful...'
else
    echo 'start mysql failed...'
fi
/bin/bash
