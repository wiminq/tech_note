#!/bin/bash
data=`mysql -u -p db_name -e "select min(id),max(id) from table_name;"`

declare -i min=`echo $data | awk '{print $3}'`
declare -i max=`echo $data | awk '{print $4}'`

echo $min" "$max
sb=$min

while [ $sb -lt $max ]
	do
		se=`expr $sb+5000`
		echo $sb" "$se>>/tmp/update_data.log
		
		mysql -u -p db_name -e "UPDATE table1,table2 SET table1.clom1 = table2.clom2 WHERE(table1.id = table2.id) AND (table1.id between $sb AND $se) AND (table1.time < table2.time);"
		
		sb=`expr $se+1`
		sleep 1
		
echo`date`>>/tmp/update_data.log
