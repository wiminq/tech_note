#!/bin/bash

mysql --default-character-set=uft8 -u -p -h -e "use db_name;delete from table_name;"
mysql --default-character-set=uft8 -u -p -h -e "use db_name;delete from table_name;"

mysqldump --default-character-set=utf8 --entended-insert -u -p --no-create-info --skip-opt -h --database db_name --table table_name > /tmp/table_name.sql
mysqldump --default-character-set=utf8 --entended-insert -u -p --no-create-info --skip-opt -h --database db_name --table table_name > /tmp/table_name.sql


mysql --default-character-set=uft8 -u -p -h db_name < /tmp/table_name.sql
mysql --default-character-set=uft8 -u -p -h db_name < /tmp/table_name.sql
