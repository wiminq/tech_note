#基于Flash设备的一些硬件和OS优化


原文: [MySQL数据库优化实践](http://www.hellodb.net/2011/07/mysql-linux-hardware-tuning.html)

thanks @hellodba

主要目录:
	
	硬件
		1.开启BBWC
		2.RAID卡配置
		3.开启Fastpath功能
		4.Fusionio参数调整
	操作系统
		1.IO调度算法
		2.NUMA设置
		3.文件系统设置
	数据库
		1.Flashcache参数
		2.Percona参数
	监控
		1.fusionio监控：fio-status命令
		2.flashcache监控：dmsetup status
		
----

##硬件

1.开启BBWC

RAID卡都有写cache(Battery Backed Write Cache)，写cache对IO性能的提升非常明显，因为掉电会丢失数据，所以必须由电池提供支持。电池会定期充放电，一般为90天左右，当发现电量低于某个阀值时，会将写cache策略从writeback置为writethrough，相当于写cache会失效，这时如果系统有大量的IO操作，可能会明显感觉到IO响应速度变慢。目前，新的RAID卡内置了flash存储，掉电后会将写cache的数据写入flash中，这样就可以保证数据永不丢失，但依然需要电池的支持。

解决方案有两种：1.人工触发充放电，可以选择在业务低谷时做，降低对应用的影响；2.设置写cache策略为force write back，即使电池失效，也保持写cache策略为writeback，这样存在掉电后丢失数据的风险。

目前，有一些硬件厂家提供了电容供电的RAID卡，没有电池充放电的问题，可以联系自己的硬件厂商。

2.RAID卡配置

关闭读cache：RAID卡上的cache容量有限，我们选择direct方式读取数据，从而忽略读cache。

关闭预读：RAID卡的预读功能对于随机IO几乎没有任何提升，所以将预读功能关闭。

关闭磁盘cache：一般情况下，如果使用RAID，系统会默认关闭磁盘的cache，也可以用命令强制关闭。

以上设置都可以通过RAID卡的命令行来完成，比如LSI芯片的RAID卡使用megacli命令。

3.开启Fastpath功能

Fastpath是LSI的新特性，在RAID控制器为SSD做了了优化，使用fastpath特性可以最大程度发挥出SSD的能力。如果使用SSD做RAID的方式，可以开启fastpath功能。关于fastpath特性，可以从LSI官网下载资料，并咨询自己的硬件提供商。

4.Fusionio参数调整

基本上，Fusionio无需做任何调整，下列三个参数可能会提升性能：

options iomemory-vsl use_workqueue=0

对于fusionio设备，忽略Linux IO调度，相当于使用NOOP。

options iomemory-vsl disable-msi=0

开启MSI中断，如果设备支持，则打开。

options iomemory-vsl use_large_pcie_rx_buffer=1

打开Large PCIE buffer，可能会提升性能。

##操作系统

1.IO调度算法

Linux有四种IO调度算法：CFQ，Deadline，Anticipatory和NOOP，CFQ是默认的IO调度算法。完全随机的访问环境下，CFQ与Deadline，NOOP性能差异很小，但是一旦有大的连续IO，CFQ可能会造成小IO的响应延时增加，所以数据库环境建议修改为deadline算法，表现更稳定。我们的环境统一使用deadline算法。

IO调度算法都是基于磁盘设计，所以减少磁头移动是最重要的考虑因素之一，但是使用Flash存储设备之后，不再需要考虑磁头移动的问题，可以使用NOOP算法。NOOP的含义就是NonOperation，意味着不会做任何的IO优化，完全按照请求来FIFO的方式来处理IO。

减少预读：/sys/block/sdb/queue/read_ahead_kb，默认128，调整为16

增大队列：/sys/block/sdb/queue/nr_requests，默认128，调整为512

2.NUMA设置

单机单实例，建议关闭NUMA，关闭的方法有三种：1.硬件层，在BIOS中设置关闭；2.OS内核，启动时设置numa=off；3.可以用numactl命令将内存分配策略修改为interleave（交叉），有些硬件可以在BIOS中设置。

单机多实例，请参考：http://www.hellodb.net/2011/06/mysql_multi_instance.html

3.文件系统设置

我们使用XFS文件系统，XFS有两个设置：su(stripe size)和sw(stirpe width)，要根据硬件层RAID来设置这两个参数，比如10块盘做RAID10，条带大小为64K，XFS设置为su=64K，sw=10。

xfs mount参数：defaults,rw,noatime,nodiratime,noikeep,nobarrier,allocsize=8M,attr2,largeio,inode64,swalloc

##数据库##

1.Flashcache参数

创建flashcache：flashcache_create -b 4k cachedev /dev/sdc /dev/sdb

指定flashcache的block大小与Percona的page大小相同。

Flashcache参数设置：

flashcache.fast_remove = 1：打开fast remove特性，关闭机器时，无需将cache中的脏块写入磁盘。

flashcache.reclaim_policy = 1：脏块刷出策略，0：FIFO，1：LRU。

flashcache.dirty_thresh_pct = 90：flashcache上每个hash set上的脏块阀值。

flashcache.cache_all = 1：cache所有内容，可以用黑名单过滤。

flashecache.write_merge = 1：打开写入合并，提升写磁盘的性能。

2.Percona参数

innodb_page_size：如果使用fusionio，4K的性能最好；使用SAS磁盘，设置为8K。如果全表扫描很多，可以设置为16K。比较小的page size，可以提升cache的命中率。

innodb_adaptive_checkpoint：如果使用fusionio，设置为3，提高刷新频率到0.1秒；使用SAS磁盘，设置为2，采用estimate方式刷新脏页。

innodb_io_capacity：根据IOPS能力设置，使用fuionio可以设置10000以上。

innodb_flush_neighbor_pages = 0：针对fusionio或者SSD，因为随机IO足够好，所以关闭此功能。

innodb_flush_method=ALL_O_DIRECT：公版的MySQL只能将数据库文件读写设置为DirectIO，对于Percona可以将log和数据文件设置为direct方式读写。但是我不确定这个参数对于innodb_flush_log_at_trx_commit的影响，

innodb_read_io_threads = 1：设置预读线程设置为1，因为线性预读的效果并不明显，所以无需设置更大。

innodb_write_io_threads = 16：设置写线程数量为16，提升写的能力。

innodb_fast_checksum = 1：开启Fast checksum特性。


##监控

1.fusionio监控：fio-status命令

Media status: Healthy; Reserves: 100.00%, warn at 10.00%

Thresholds: write-reduced: 96.00%, read-only: 94.00%

Lifetime data volumes:

Logical bytes written : 2,664,888,862,208

Logical bytes read    : 171,877,629,608,448

Physical bytes written: 27,665,550,363,560

Physical bytes read   : 223,382,659,085,448

2.flashcache监控：dmsetup status

read hit percent(99)

write hit percent(51)

dirty write hit percent(44)