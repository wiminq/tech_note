#online-DDL steps&tips

-----
##基本步骤
**1.确认触发器使用**

**2.服务器删除触发器：**

**3.确认（所有服务器）没有大查询，在写库执行变更，**

**4.在相关服务器上尽快给需要的字段加上索引**

**5.原表和ghost表的一致性校验**

**6.ghost表发布上线**

**7.还原相关服务器的触发器**


----
`tips:`

使用如上语句生成语句进行外键、触发器检查，使用生成的语句检查主从一致性
使用生成的语句建立ghost表
使用生成的语句检查源表和ghost表一致性
使用生成的语句重命名表


特别注意set @alterstatment='xxx';

这个里面 不 包括alter table table_name这部分

不能输入中文注释，
中文注释可以在创建好xxx_new_xx表以后（不需要等待到onlie ddl copy完成）
手工alter 修改注释，这个不需要copy表的。

不能包含反引号"`"，这个是shell下的特殊字符，会出问题

单引号“'”要做一次转义

-----
##通用步骤：

use xxx

set @mytablename='xxx';

set @alterstatment='xxx';

set @mydbname=database();

select * from information_schema.key_column_usage where 
table_schema=@mydbname and table_name=@mytablename and 
referenced_table_name is not null;

select * from information_schema.key_column_usage where 
referenced_table_schema=@mydbname and 
referenced_table_name=@mytablename;

select * from information_schema.triggers where 
event_object_schema=@mydbname and 
event_object_table=@mytablename;

select concat('select 
sum(crc32(concat(ifnull(',group_concat(column_name 
separator ',\'NULL\'),ifnull('),',\'NULL\')))) as sum 
from ',table_name,';') as sqltext from 
information_schema.columns where table_schema=@mydbname 
and table_name=@mytablename \G

select concat('select 
sum(crc32(concat(ifnull(',group_concat(column_name 
separator ',\'NULL\'),ifnull('),',\'NULL\')))) as sum 
from ',table_name,' union all select 
sum(crc32(concat(ifnull(',group_concat(column_name 
separator ',\'NULL\'),ifnull('),',\'NULL\')))) as sum 
from ',table_name,'_new',date_format(now(),'_%Y%m
%d'),' ;') as sqltext from information_schema.columns 
where table_schema=@mydbname and table_name=@mytablename 
\G

select concat('python oak-online-alter-table -u 
',substring_index(user(),'@',1),' --ask-pass -S 
',@@global.socket,' -d ',@mydbname,' -t ',@mytablename,' 
-g ',@mytablename,'_new',date_format(now(),'_%Y%m%d'),' -
a "',@alterstatment,'" --sleep=300 --skip-delete-pass') 
as sqltext \G

select concat('use ',@mydbname) as sqltext1,'set names utf8;' as sqltext2,concat('rename table ',@mytablename,' to ',@mytablename,date_format(now(),'_%Y%m%d'),',',@mytablename,'_new',date_format(now(),'_%Y%m%d'),' to ',@mytablename,';') as sqltext3 \G

--------
##使用范例

1.确认触发器使用——已经和xxx确认过，在变更完成后对这个表进行一次全量抽取

2.xxx等相关服务器删除触发器：

drop trigger a;

drop trigger b;

drop trigger c;


3.确认（所有服务器）没有大查询，在写库执行变更，写库上 ：
python oak-online-alter-table -u  --ask-pass -S /tmp/mysql3306.sock -d  -t  -g  -a "add order_type tinyint NOT NULL DEFAULT 0,add last_update_time timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP" --sleep=300 --skip-delete-pass

4.在xxx相关服务器上尽快给last_udpate_time等需要的字段加上索引
alter table table_name add index (last_udpate_time);

5.原表和ghost表的一致性校验
select sum(crc32(concat(ifnull(id,'NULL'),ifnull(user_id,'NULL'),ifnull(relate_id,'NULL'),ifnull(type,'NULL'),ifnull(mark,'NULL'),ifnull(source,'NULL'),ifnull(operator,'NULL'),ifnull(ip,'NULL'),ifnull(add_time,'NULL')))) as sum from table union all select sum(crc32(concat(ifnull(id,'NULL'),ifnull(user_id,'NULL'),ifnull(relate_id,'NULL'),ifnull(type,'NULL'),ifnull(mark,'NULL'),ifnull(source,'NULL'),ifnull(operator,'NULL'),ifnull(ip,'NULL'),ifnull(add_time,'NULL')))) as sum from table_new_20140422 ;

6.ghost表发布上线
rename table old_table to table_name,table_name to table;

7.还原xxx等相关服务器的触发器
CREATE DEFINER=`root`@`localhost` TRIGGER `a` AFTER INSERT ON `table` FOR EACH ROW replace into  table_changelog_bi(id,isdel_bi) values(NEW.id,0)
CREATE DEFINER=`root`@`localhost` TRIGGER `b` AFTER UPDATE ON `table` FOR EACH ROW replace into  table_changelog_bi(id,isdel_bi) values(NEW.id,0)
CREATE DEFINER=`root`@`localhost` TRIGGER `c` AFTER DELETE ON `table` FOR EACH ROW replace into table_changelog_bi(id,isdel_bi) values(OLD.id,1)


