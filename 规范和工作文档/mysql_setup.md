#MySQL setup 

1 新建用户
useradd apps

2 把原有目录移走
mv /db /db_old

3 启动安装脚本 
vim db_install.sh
sh db_install.sh

4 目前tar包ln软连接有问题
mv /mysql /mysql_old
ln -s  /mysql-5.5.30-linux2.6-x86_64/ /mysql5

/mysql5.sh start

cd /mysql/etc/
rm my.cnf
ln -s /mysql/my3306.cnf my.cnf


`5 增加本机oradba监控`

su
crontab -e 
*/5 * * * * /start_mon.sh > /dev/null 2>&1






