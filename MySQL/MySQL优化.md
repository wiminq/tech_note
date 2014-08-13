#MySQL优化

`提纲`

## 一 DB schema优化

1 **字段类型**设计

2 索引设计:**索引注意事项**

3 垂直 水平划分:拆分:(vipship 购物车 user)

4 存储引擎

## 二 SQL优化

1 定位 **(slowlog 管理)**

2 分析 **explain;show profile**

3 优化 **具体措施** 

4 锁优化

## 三 参数优化


## 四 OS 硬件优化


## 五 应用优化



----

###DB schema设计优化:
`字段类型:`

	尽可能小
	手机号不用int
	IP可以用int INET_ATON INET_NTOA
	状态信息
	时间 timestamp 自动更新功能 BI抽数
	
`索引`



----
###SQL优化
`定位`

	5.6 ms级
	my.cnf slow-query-log=1;slow-quey=log-file=/;long-query-time=2

`监控截取某段时间`

	sed -n '/#Time: 110720 16:17:39/,/end/p' mysql-slow.log>slow.llg

`mysqldumpslow分析`

	分析前十条:mysqldumpslow -S t -t 10 slow.log
	
`explain分析`

	DESC profile 5.6 trace
	explain extended 
	show warnings
	show status like 'com_%';
	connections;uptime;slow_queries
	
`explain参数含义`

`SQL优化案例`
	
`profile`
	
	show profile 
	select @@have_profiling
	show profile for query x;
	

----
###参数优化
`重点参数`

----
###



