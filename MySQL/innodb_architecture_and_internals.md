#InnoDB Architecture and Internals

@percona PPT
## version

## General Architecture 
	
	OLTP(Oracle like)
	MySQL API storage
	Row based storage; Row lock;MVCC
	Data->Tablespace
	Log->circalar log files
	BP:data page

----
`Storage files layout`

Physical Structure of Innodb Tablespaces and logs 

## InnoDB Tablespace&Log

	tablespace WAL
	innodb_file_per_table=1
	Format:tablespace;segment (like a file);extent 
	each table is set of index "index organized table"
	index:leaf node ;non-leaf-node
	segment:
		rollback segment
		insert buffer segment
		
## Log file

ib_logfile(default 2)

	log header:store information about last checkpoint
	log NOT organized in pages,but records
		record 512 bytes matching disk sector
	log record format:"physiological"
		store page# and operation to do on it 
	only REDO operations are store in logs
## separate undo tablespace
	
	5.6 :
		innodb_undo_directory
		innodb_undo_tablespace
		innodb_undo_logs
	can store it in SSD

## Thread Arch

	MySQL thread for exec
		normally thread per connection
	Transaction exec by such thread
		Little benefit from Multi-core for single query
	Innodb_thread_concurrency can be used to limit number of executing threads
		reduce contention
	
	
