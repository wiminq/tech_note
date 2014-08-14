#MySQL复制

master dump binlog

推 -->

slave 
	
	IO thread
	SQL thread 

show master status;

show slave status;

	master:postion
	slave:read_master_log_pos
	
`过程:`

	grant replication slave on *.* to 'xx'@'xx' identified  by 'passwd';
	my.cnf server-id
	mysqldump --single-transaction --master-data 
	import
	start slave
	show slave status;
	
`问题解决`
	
	stop slave;
	set global sql_slave_skip_counter=1;
	start slave;
	
	binlog_ignore_db
	