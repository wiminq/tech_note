#SQL优化 案例

`5.6之前的子查询`
	
	select * from A where filed in (select field from B where id = 'xxx');
	可以内层临时表,再查再撤销
	select  a.* from A a join (select field from B where id = 'xxx') on a.filed = b.filed


`like %xx%`

	select * from A where name like '%xx%'
	select id from A where name like '%xx%'
		id是主键,索引即可得到信息,覆盖索引
		 
~~`limit分页优化 待补充`~~

	limit 1000,10 
		where id >=1000 order by id limit 10;
	select id,title,create_date from x order by create_date asc limit 1000,10;
	select a.id,a.title,a.create_date from x order by create_date asc limit (1000,1) b on a.id>= b.id limit 10;


`count(*)`
	
	innodb慢 count(辅助索引)快于count(*) //不要在主库执行
	select count(*) from user;		6min
	select count(*) from user where sid>=0;	2min
	select count(distinct k) from sbtest;  0.5s
	select count(*) from (select distinct k from sbtest) tmp; 0.0s
	
`or 用不上索引`

	改为union all
	select * from user where name ='a' or age=41;
	select * from user where name ='a' union all select * from user where nage=41;


`where 替换having`	



`ON DUPLICATE KEY UPDATE`
	
	主键冲突处理,冲突update 不冲突insert 
	insert	into gg values (3,'id') ON UNPLICATE KEY UPDATE
	