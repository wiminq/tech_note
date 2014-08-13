#explain参数含义



id 

`select_type`

	SIMPLE 
	primary
	union
	subquery
	
table 

`type`

	ALL:全表扫描
		select * from film where rating>9; 
	index:索引全扫描
		select title from film;
	range:索引范围扫描
		select * from payment where customer_id >=300 and usetom_id<400;
	ref:非唯一索引扫描或者唯一索引的前缀索引,返回匹配某个单独值得记录行;
		select * from payment where customer_id=300
		也常出现在join中
		select b.*,a.* from payment a,customer b where a.customer_id=b.customer_id;
	eq_ref:索引为唯一索引,每个索引键值只有一条匹配,即多表连接中使用PK,unique key为关联条件
		select * from a,b where a.id=b.id;
	const;system:单表中一个匹配行,查询很快可作为常量
	NULL
	


possible_keys 

key  

key_len 

ref 

rows 

Extra


