#InnoDB 事务和日志 实现

`ACID`
	
	A原子性:redo log
	C一致性:undo log
	I隔离性:锁实现
	D持久性:redo log;
	
`redo undo`

都是一种恢复操作

	redo:恢复提交事务修改的页操作
		物理日志 page的物理修改
			顺序写
		参数:
			redo log file
			redo log buffer
			ib_logfile
			innodb_log_buffer_size=
			innodb_mirrored_log_group
			innodb_log_group_home_dir
			innodb_log_file_in_group
			innodb_log_fiel_size
	undo:回滚行记录到最初版本
		逻辑日志 每行记录
		实现回滚;MVCC
			随机读写
			
`物理日志与逻辑日志`

	物理日志:
		every page的物理修改
		量大;幂等
	逻辑日志:
		对表的操作,但是恢复可能会不一致;
			如插入为全部完成时宕机回滚困难,未知状态
	结论:
		physical to page
		logical within a page
	
	undo:
		也会产生redo log 伴随redo log产生;也需要持久化存储;
		undo segment 共享表空间内
		逻辑恢复,因为并发所以不能将一个页面内的其他记录也回到开始的样子.
		undo :insert->delete
		MVCC undo完成,当用户读取一行记录时,若该记录已经被其他事物占用,可undo读取之前的状态实现非锁定读.
		
		
					
innodb_flush_log_at_trx_commit
	
	0
	1
	2





`redo-log binlog`

	redo log:
		innodb产生 物理格式 事物不断写入
	binlog:
		逻辑日志 MySQL server
		提交时写入
		
	log block:512字节 与扇区大小相同,可保证原子性,不需要double write
	
`LSN`

八字节
	
	redo log
	checkpoint 
	页版本
	
	log sequence number
	log flushed up to
	last checkpoint at
	
	