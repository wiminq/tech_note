#!/bin/bash

DATE=`date +"%Y%m%d"`
TDATE=`date +"%Y%m%d" --date="-2 day"`

#mysqldump -h 127.0.0.1 --default-charcter-set=utf8 --locak-tables --skip-add-drop-table --quick -u -p --all-databases > /backup/alldb_$DATE.sql

for ii in `mysql -h 127.0.0.1 -u -p -e "SELECT max(TABLE_SCHEMA) FROM information_schema.tables WHERE TABLE_SCHEMA not in('information_schema','mysql','performance_schema','test') group by TABLE_SCHEMA;" | grep -v TABLE_SCHEMA`;do
	echo ii
	mysqldump -h 127.0.0.1 --default-character-set=utf8 --lock-table --quick -u -p $ii > backup/$ii-$DATE.sql
	done

rm -rf /backup/$ii-$TDATE.sql





