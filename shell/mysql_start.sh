#!/bin/bash

MYSQL_BASE=/root

export PATH=$MYSQL_BASE/bin:/usr/sbin:/usr/bin:/sbin:/bin
export LD_LIBRARY_PATH=$MYSQL_BASE/lib

if [ "$1" = "stop" ];then
	$MYSQL_BASE/bin/mysqladmin --default-file=$MYSQL_BASE/etc/my.cnf -u -p shutdown
elif [ "$1" = "restart" ]
	$MYSQL_BASE/bin/mysqladmin -default-file=$MYSQL_BASE/etc/my.cnf -u -p s
hutdown
	$MYSQL_BASE/bin/mysqld_safe -default-file=$MYSQL_BASE/etc/my.cnf &
leif [ "$1" = "start" ]
	$MYSQL_BASE/bin/mysqld_safe -default-file=$MYSQL_BASE/etc/my.cnf &
else 
	echo "usage:$0 start|stop|restart"
fi

