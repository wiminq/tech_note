#MySQL restart checklist


##1:sure DB QPS is 0
	check oradba log
	tailf /log/oradba.log

##2:LVS remove
	ipvsadm -ln
##3:shutdown database
	/mysql.sh stop
##4:restart server
	init 6
##5:check network
	ifconfig 
	检查bond0的网卡成员是否up
##6:check lvs
	ip a查看vip有无启动在lo网口上，如没有启动，执行下面的命令：
	/usr/sbin/lvs_server start
##7:ping DB
	SA:ping DB from app
##8:check user ulimit
	su - user
	ulimit -a
	正确值：core file size          (blocks, -c) 0
	data seg size           (kbytes, -d) unlimited
	scheduling priority             (-e) 0
	file size               (blocks, -f) unlimited
	pending signals                 (-i) 1031911
	max locked memory       (kbytes, -l) 128849018880
	max memory size         (kbytes, -m) unlimited
	open files                      (-n) 131072
	pipe size            (512 bytes, -p) 8
	POSIX message queues     (bytes, -q) 819200
	real-time priority              (-r) 0
	stack size              (kbytes, -s) unlimited
	cpu time               (seconds, -t) unlimited
	max user processes              (-u) unlimited
	virtual memory          (kbytes, -v) unlimited
	file locks                      (-x) unlimited
##9:start MySQL
	/mysql.sh start
	tailf /log/mysql_error.log
##10:check status
	show processlist
	show slave status
	check zabbix
	