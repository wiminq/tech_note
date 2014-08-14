#!/bin/bash

read -p "选择安装种类 1:mysql 2:redis 3:MC 4:Mariadb: default 1):" install_type

if [ ! -n "$install_type" ]
 then
   select_type=1
 else
   select_type=$install_type
fi

echo "need hostname"

case "$select_type" in
    '1') # Mysql
    echo "mysql 主机名样例: num-db-mysql.corp.com"

    echo -e "\n"
    ;;
    '2') # redis
    
    echo "redis 主机名样例: num-db-redis.corp.com"

    echo -e "\n"
    
    ;;
    '3') # MC
    
    echo "mc 主机名样例: num-db-mc.corp.com"

    echo -e "\n"
    
    ;;
    '4') # Mariadb
    
    echo "Mariadb 主机名样例: num-db-mysql.corp.com"

    echo -e "\n"
    
    ;;
      *)
            echo "请选择1:mysql 2:redis 3:MC 4:Mariadb"           
            exit 1          
esac    

 

read -p "input ip for this server):" local_ip

if [ ! -n "$local_ip" ]
 then
   echo "please input ip for this server,then next"
   exit 1
 
fi


read -p "input new hostname for pubbet):" new_hostname

if [ ! -n "$new_hostname" ]
 then
   echo "please input new hostname for pubbet,then next"
   exit 1
 
fi


case "$select_type" in
    '1') # Mysql
    
            read -p "input db role name for wiki db list" role_name

            if [ ! -n "$role_name" ]
             then
               echo "please input db role name for wiki db list,then next"
               exit 1
             
            fi
               
            read -p "input new mysql server-id:" server_id
            if [ ! -n "$server_id" ]
             then
               echo "please input server-id,then next"
               exit 1
             
            fi
            
            read -p "setup mysql read_only  no/yes default no :" comment_read_only
            if [ ! -n "$comment_read_only" ]
             then
               var_read_only="no"
             else
               var_read_only=$comment_read_only
            fi
            
            echo -e "\n"
            cur_memory=`free -m | grep "Mem" | awk '{print $2, "MB"}'`
            echo "current system total memory: $cur_memory"
            echo -e "\n"
            read -p "input innodb_buffer_pool_size(g) defaout 32:" size_buffer_pool
            if [ ! -n "$size_buffer_pool" ]
             then
               var_buffer_pool=32
             else
               var_buffer_pool=$size_buffer_pool
            fi
            
            echo -e "\n"
            read -p "input mysql wait_timeout defaout 120:" wait_timeout
            if [ ! -n "$wait_timeout" ]
             then
               var_wait_timeout=120
             else
               var_wait_timeout=$wait_timeout
            fi
            
            ;;
 
    '2') # redis 
            read -p "input redis port default 6379:" redis_port
            if [ ! -n "$redis_port" ]
             then
               var_redis_port=6379
             else
               var_redis_port=$redis_port
            fi
            
            read -p "input redis maxmemory(gb) default 2:" redis_memory
            if [ ! -n "$redis_memory" ]
             then
               var_redis_memory=2
             else
               var_redis_memory=$redis_memory
            fi
            
            read -p "is role slave?  no/yes default no :" redis_slave
            if [ ! -n "$redis_slave" ]
             then
               var_redis_slave="no"
             else
               var_redis_slave=$redis_slave
            fi
            
            var_yes="yes"    
            if [ "$var_redis_slave" = "$var_yes" ];then
             
                read -p "input master IP :" redis_master_ip
                
                if [ ! -n "$redis_master_ip" ]
                 then
                   echo "please input redis master ip,then next"
                   exit 1
                 
                fi
                
                read -p "input Master Port default ${var_redis_port} :" redis_master_port
                
                if [ ! -n "$redis_master_port" ]
                 then
                   var_redis_master_port=${var_redis_port}
                   
                 else
                 
                   var_redis_master_port=$redis_master_port
                 
                fi
            
            fi
            
            ;;         
 
    '3') # MC 
            read -p "input MC port default 11211:" mc_port
            if [ ! -n "$mc_port" ]
             then
               var_mc_port=11211
             else
               var_mc_port=$mc_port
            fi
            
            read -p "input MC memory setup(m) default 4096:" mc_memory
            if [ ! -n "$mc_memory" ]
             then
               var_mc_memory=4096
             else
               var_mc_memory=$mc_memory
            fi
            
            ;; 
            
    '4') # Mariadb
    
            read -p "input db role name for wiki db list, for example 配置中心(主):" role_name

            if [ ! -n "$role_name" ]
             then
               echo "please input db role name for wiki db list,then next"
               exit 1
             
            fi
               
            read -p "input new mysql server-id:" server_id
            if [ ! -n "$server_id" ]
             then
               echo "please input server-id,then next"
               exit 1
             
            fi
            
            read -p "setup mysql read_only  no/yes default no :" comment_read_only
            if [ ! -n "$comment_read_only" ]
             then
               var_read_only="no"
             else
               var_read_only=$comment_read_only
            fi
            
            echo -e "\n"
            cur_memory=`free -m | grep "Mem" | awk '{print $2, "MB"}'`
            echo "current system total memory: $cur_memory"
            echo -e "\n"
            read -p "input innodb_buffer_pool_size(g) defaout 32:" size_buffer_pool
            if [ ! -n "$size_buffer_pool" ]
             then
               var_buffer_pool=32
             else
               var_buffer_pool=$size_buffer_pool
            fi
            
            echo -e "\n"
            read -p "input mysql wait_timeout defaout 120:" wait_timeout
            if [ ! -n "$wait_timeout" ]
             then
               var_wait_timeout=120
             else
               var_wait_timeout=$wait_timeout
            fi
            
            ;;
      *)
            echo "please choose  1:mysql 2:redis 3:MC 4:Mariadb"
            exit 1          
esac

cd /

wget mysql.tar.bz2

echo -e "\n"

echo "uncompress tar,please wait"

echo -e "\n\n"

tar xjf  mysql.tar.bz2

rm -rf /mysql.tar.bz2


yum install expect -y
yum install libaio -y
yum install dos2unix -y


case "$select_type" in
    '1') # Mysql
    
        mv /etc/my.cnf /etc/my.cnf.bak
        ln -s /mysql/my3306.cnf /etc/my.cnf
        
        sed -i "s/server-id=621133306/server-id=${server_id}/g" /mysql/my3306.cnf
        
        if [ $var_buffer_pool -ne 32 ]
         then
           sed -i "s/innodb_buffer_pool_size=32G/innodb_buffer_pool_size=${var_buffer_pool}G/g" /mysql/my3306.cnf
         
        fi
        
        if [ $var_wait_timeout -ne 120 ]
         then
           sed -i "s/wait_timeout=120/wait_timeout=${var_wait_timeout}/g" /mysql/my3306.cnf
           sed -i "s/interactive_timeout=120/interactive_timeout=${var_wait_timeout}/g" /mysql/my3306.cnf
        fi
        
        
        var_no="no"    
        if [ "$var_read_only" = "$var_no" ];then
           sed -i "s/read_only/#read_only/g" /mysql/my3306.cnf
         
        fi
       
   
         su - root -c "/sh/mysql5.sh start"
         
         su - root -c "/usr/bin/crontab /sh/cron/crontab.txt"
         
         #add db role name
         
         /bin/mysql -u -p -h -P 3307 -e "use config_table;insert into tag(ip,role) values('${local_ip}','${role_name}')"
                  
         echo "successful"
    
         ;;
    
    '4') # Mariadb
    
        mv /etc/my.cnf /etc/my.cnf.bak
        ln -s /mysql/mariadb3306.cnf /etc/my.cnf
        
        sed -i "s/server-id=621133306/server-id=${server_id}/g" /mysql/mariadb3306.cnf
        
        if [ $var_buffer_pool -ne 32 ]
         then
           sed -i "s/innodb_buffer_pool_size=32G/innodb_buffer_pool_size=${var_buffer_pool}G/g" /mysql/mariadb3306.cnf
         
        fi
        
        if [ $var_wait_timeout -ne 120 ]
         then
           sed -i "s/wait_timeout=120/wait_timeout=${var_wait_timeout}/g" /mysql/mariadb3306.cnf
           sed -i "s/interactive_timeout=120/interactive_timeout=${var_wait_timeout}/g" /mysql/mariadb3306.cnf
        fi
        
        
        var_no="no"    
        if [ "$var_read_only" = "$var_no" ];then
         
           #echo  $var_read_only
           sed -i "s/read_only/#read_only/g" /mysql/mariadb3306.cnf
         
        fi
       
        
         
         su - root -c "/sh/mariadb5.sh start"
         
         su - root -c "rm -rf /svr/mysql5"        #delete original link,replace to mariadb
         
         su - root -c "ln -s /svr/mariadb  /svr/mysql5"
         
         su - root -c "/usr/bin/crontab /sh/cron/crontab.txt"
    	  /bin/mysql -u -p -h -P 3307 -e "use config_table;insert into tag(ip,role) values('${local_ip}','${role_name}')"
                  
         echo "successful"
    
      
   
         ;;
         

