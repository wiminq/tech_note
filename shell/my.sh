#!/bin/bash

#thanks:@ruzuojun
#ONLY ROOT!
#ONLY RHEL&CentOS

#config mysql FIRST
###########################################################################
host="127.0.0.1" #mysql server
port="3306"  #mysql port
username="root" #mysql username
password="123456" 
basedir=/data/mysql #default /usr/local/mysql
datadir=""  #default $basedir/data

#only ROOT
if [ $EUID -ne 0 ]; then
    echo "[ERROR]: Please run this script with root privileges."
    exit 1
fi

#only RHEL&CentOS
if [ ! -f /etc/redhat-release ]; then
    echo "[ERROR]: Sorry, this script is for CentOS/RHEL only."
    exit 1
fi

# The following variables are only set for letting mysql.server find things.
#############################################################################
if test -z "$basedir"
then
  basedir=/usr/local/mysql
  bindir=/usr/local/mysql/bin
  if test -z "$datadir"
  then
    datadir=/usr/local/mysql/data
  fi
  sbindir=/usr/local/mysql/bin
  libexecdir=/usr/local/mysql/bin
else
  bindir="$basedir/bin"
  if test -z "$datadir"
  then
    datadir="$basedir/data"
  fi
  sbindir="$basedir/sbin"
  libexecdir="$basedir/libexec"
fi

# export PATH
#############################################################################
PATH="/sbin:/usr/sbin:/bin:/usr/bin:$basedir/bin"
export PATH

#parameter define
#############################################################################
login_param="-h$host -P$port -u$username -p$password"
mode=$1
value=$2

#Command 
#############################################################################
case "$mode" in
  'dba')
    cd $basedir

    if test -x $bindir/mysql
    then
      $bindir/mysql $login_param 
    else
      echo  "Couldn't find MySQL server ($bindir/mysql)"
    fi
    ;;

    'listen')
    #Print the mysql listen port; Command: #my listen
        listen=`netstat -nutpl |grep LISTEN |grep mysql`
        if [ "$listen" == "0" ];then
                echo "This server is not listen mysql. please check mysql server status."
        else
                netstat -nutpl |grep LISTEN |grep mysql
        fi
    ;;

    'ping')
    #Check if mysqld is alive; Command: #my ping
    for((;;))
      do
        if [ -f "$bindir/mysqladmin" ] ;then
                $bindir/mysqladmin $login_param ping
                echo "************************"
        else
                echo "The mysqladmin script is not find in $bindir."
		exit
        fi
        sleep 1
      done
    ;;	

    'status-inc')
    #Check mysql status change value; Command: #my status-inc [parameter]; Example: my status-inc Buffer
        if [ -f "$bindir/mysqladmin" ] ;then
                $bindir/mysqladmin $login_param extended-status -r -i 3 |grep "$value"
        else
                echo "The mysqladmin script is not find in $bindir."
                exit
        fi
    ;;

  'active')
    #Print mysql processlist once ; Command: #my active
        echo "**********************************************************************************************************************************"
        num_active=`$bindir/mysql $login_param  -e 'show full processlist;'|grep -v Sleep|grep -v Command |wc -l`
        num_sleep=`$bindir/mysql $login_param  -e 'show full processlist;'|grep  Sleep|grep -v Command |wc -l`
        echo "Active sessions:$num_active  Sleep sessions:$num_sleep"
        echo "**********************************************************************************************************************************"
        $bindir/mysql $login_param  -e "show full processlist;"|grep -v Sleep
        echo "**********************************************************************************************************************************"
    ;;

  'top')
    #Print mysql processlist ever and again; Commdnd: #my top
    for((;;))
	do
	clear
        echo "**********************************************************************************************************************************"
        num_active=`$bindir/mysql $login_param  -e 'show full processlist;'|grep -v Sleep|grep -v Command |wc -l`
        num_sleep=`$bindir/mysql $login_param  -e 'show full processlist;'|grep  Sleep|grep -v Command |wc -l`
        echo "Active sessions:$num_active  Sleep sessions:$num_sleep"
	echo "**********************************************************************************************************************************"
        $bindir/mysql $login_param  -e "show full processlist;"|grep -v Sleep
	echo "**********************************************************************************************************************************"
	sleep 2
	done
    ;;

    'kill')
    #Kill session by session id ; Command: #my kill [pid parameter]; Example: my kill 20000
	if [[ "$value" =~ "^[0-9]+$" ]] ;then
		$bindir/mysql $login_param -e "kill $value"
        else
		echo "The value is wrong, must be a number"
	fi
    ;;

    'killall')
    #Kill all session if time > N seconds; Command: #my killall [N second parameter]; Example: my killall 60
	if [[ "$value" =~ "^[0-9]+$" ]] ;then
        	$bindir/mysql $login_param  -e 'show processlist'|grep -v -i -E "system users|replication|processlist|Sleep|Command|Connect|master|Slave|information_schema"|awk '{if($6>'$value')print $1}' |while read line; do $bindir/mysql $login_param  -e "kill query $line" ;  echo "mysql processes id $line been killed"; done
    	else
                echo "The value is wrong, must be a number"
        fi
	;;

    'queryavg')
    #Print query number per seconds; Command: #my queryavg
    	a=`$bindir/mysql $login_param -e "show global status like 'Queries';"|grep Queries|awk '{if($2>0) print $2}'`
	sleep 2
	b=`$bindir/mysql $login_param -e "show global status like 'Queries';"|grep Queries|awk '{if($2>0) print $2}'`
	let c=($b-$a)/2
	echo $c
    ;;

    'deadlock')
    #Print dead locks info; Command: #my deadlock
        $bindir/mysql $login_param -e "select * from information_schema.INNODB_TRX a, information_schema.INNODB_LOCKS b, information_schema.INNODB_LOCK_WAITS c, information_schema.INNODB_TRX d where a.trx_query like '%T_PRICING_RESULT%' and a.trx_id=b.lock_trx_id and a.trx_id=c.requesting_trx_id and c.blocking_trx_id=d.trx_id\G"
    ;;	

    'errorlog')
    #Print last 50 line error log info; Command: #my errorlog 
    	errorlog_file=`$bindir/mysql $login_param -e "show variables like 'log_error';"|grep log_error |awk -F ' ' '{print $2}'`
	echo "**********************************************************************************************************************************"
	tail -n 50 $errorlog_file	
	echo "**********************************************************************************************************************************"
	echo "MySQL Error log write at: $errorlog_file"
	echo "**********************************************************************************************************************************"
	;;

    'tailerror')
    #Print error log info real time; Command: #my tailerror
        errorlog_file=`$bindir/mysql $login_param -e "show variables like 'log_error';"|grep log_error |awk -F ' ' '{print $2}'`
        echo "**********************************************************************************************************************************"
        tail  -f  $errorlog_file
        ;;

    'mycnf')
    #Print my.cnf info; Command: #my mycnf [parameter] ;you can find my.cnf file by #mysql  --verbose --help |grep -A 1 'Default options'
    	if [ -f "/etc/my.cnf" ]; then
		more /etc/my.cnf |grep "$value"
	elif [ -f "/etc/mysql/my.cnf" ]; then
		more /etc/mysql/my.cnf |grep "$value"
	elif [ -f "$basedir/etc/my.cnf" ]; then
		more $basedir/etc/my.cnf |grep "$value"	
	elif [ -f "~/.my.cnf" ]; then
		more ~/.my.cnf |grep "$value"
	else
		echo "Error:not find my.cnf in /etc/my.cnf /etc/mysql/my.cnf $basedir/etc/my.cnf ~/.my.cnf"
	fi
    ;;	

    'variables')
    #Print mysql variables info; Command: #my variables [parameter]
        $bindir/mysql $login_param -e "show variables like '%$value%';"
        ;;

    'status')
    #Print mysql status info; Command: #my status [parameter] ; Example: #my status locks
        $bindir/mysql $login_param -e "show status like '%$value%';"
        ;;

    'innodb')
    #Print innodb status info; Command: #my innodb
        $bindir/mysql $login_param -e "show engine innodb status;"
        ;;

    'mutex')
    #Print mutex status info; Command: #my mutex
        $bindir/mysql $login_param -e "show engine innodb mutex;"
        ;;

     'exec')
    #Execute SQL statement; Command:#my exec [SQL parameter] ; Example: #my exec "select * from test.user" 
	if [ "$value" == "" ];then
		echo "Error:please give a SQL statement."
	else
        	$bindir/mysql $login_param -e "$value;"
	fi
        ;;

    'user')
    #Print mysql user list info; Command: #my user 
                $bindir/mysql $login_param -e "select user,host,password from mysql.user;" 
     ;;

     'grants')
    #Print mysql user grant info; Command: #my grants [parameter] ; Example: #my grants root@localhost
                $bindir/mysql $login_param -e "show grants for $value"
     ;;

    'history')
    #Print mysql history file info; Command: #my history [parameter] ; Example: #my history update
                cat /root/.mysql_history |grep "$value"
     ;;

    'doc')
    #Print mysql refman doc; Command: #my doc [parameter] ; Example: #my doc 'create table'
                $bindir/mysql $login_param -e "help $value"
     ;;

     'slave')
    #Print mysql slave info; Command: #my slave 
        c=`$bindir/mysql $login_param -e "show slave status;" |wc -l`   
	if [ "$c" == "0" ];then
		echo "Note:This mysql server is not a slave."
	else
		$bindir/mysql $login_param -e "show slave status\G"
	fi
     ;;

     'delay')
    #Print mysql slave delay to master time ever and again; Command: #my delay 
     for((;;))
        do
        c=`$bindir/mysql $login_param -e "show slave status;" |wc -l`
        if [ "$c" == "0" ];then
                echo "Note:This mysql server is not a slave."
        else
                $bindir/mysql $login_param -e "show slave status\G" |grep Seconds_Behind_Master
                echo "*************************************************"
        fi
      sleep 1
      done
     ;;

    'admin')
      #Execute mysqladmin Command; Command: #my admin [Command parameter]; Example: #my admin stop-slave
          if [ -f "$bindir/mysqladmin" ] ;then
                  $bindir/mysqladmin $login_param $value
          else
                  echo "The mysqladmin script is not find in $bindir."
                  exit
          fi
      ;;
	
    '--help')
    #for help
	echo "my help info:"
	echo "support-site:www.ruzuojun.com  bug-report:ruzuojun@yihaodian.com"
	echo "======================================================================="
	echo "--help     Print my tools help info; Command: #my --help"
	echo "dba        Login mysql server; Command: #my dba"	
	echo "doc        Print mysql refman doc onine; Command: #my doc [parameter] ; Example: #my doc 'create table'"
	echo "ping       Check if mysqld is alive; Command: #my ping"
	echo "listen     Print the mysql listen port; Command: #my listen"
	echo "active     Print mysql processlist once ; Command: #my active"
	echo "top        Print mysql processlist ever and again; Commdnd: #my top"
	echo "kill       kill session by session id ; Command: #my kill [pid parameter]; Example: my kill 20000"
	echo "killall    kill all session if time > N seconds; Command: #my killall [N second parameter]; Example: my killall 60"
	echo "queryavg   Print query number per seconds; Command: #my queryavg"
	echo "deadlock   Print desd locks info; Command: #my deadlock"
	echo "errorlog   Print last 50 line error log info; Command: #my errorlog"
	echo "tailerror  Print last error log info real time; Command: #my tailerror"
	echo "mycnf      Print my.cnf info; Command: #my mycnf [parameter] ;you can find my.cnf file by #mysql  --verbose --help |grep -A 1 'Default options'"
	echo "variables  Print mysql variables info; Command: #my variables [parameter]"
	echo "status     Print mysql status info; Command: #my status [parameter] ; Example: #my status locks"
	echo "status-inc Check mysql status change value; Command: #my status-inc [parameter]; Example: my status-inc Buffer"
	echo "innodb     Print innodb status info; Command: #my innodb"
	echo "mutex      Print innodb mutex status info; Command: #my mutex"
	echo "user       Print mysql user list info; Command: #my user"
	echo "grants     Print mysql user grant info; Command: #my grants [parameter] ; Example: #my grants root@localhost"
	echo "history    Print mysql history file info; Command: #my history [parameter] ; Example: #my history update"
	echo "slave      Print mysql slave info; Command: #my slave"
	echo "delay      Print mysql slave delay to master time ever and again; Command: #my delay"
	echo "exec       Execute SQL statement; Command:#my exec [SQL parameter] ; Example: #my exec 'select * from test.user' "
	echo "admin      Execute mysqladmin Command; Command: #my admin [Command parameter]; Example: #my admin stop-slave"
	exit	
    ;;
    *)
	echo "Please input '#my --help' to read the help info."
    ;;

esac

exit 0
