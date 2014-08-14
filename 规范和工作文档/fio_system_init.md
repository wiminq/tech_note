#FIO_system_init
fdisk -l

tar xvf release2.6.2.tar

cd release2.6.2

sh install

shannon-detach /dev/scta

shannon-format -b 4k /dev/scta

shannon-attach /dev/scta

mkfs.xfs -f -i attr=2 -l lazy-count=1,sectsize=4096 -b size=4096 -d sectsize=4096 -L data /dev/dfa

mkdir /mysql/

mount -o `rw,noatime,nodiratime,noikeep,nobarrier,allocsize=100M,attr2,largeio,inode64,swalloc /dev/dfa /mysql`

vi /etc/fstab


`/dev/dfa                /mysql                  xfs     rw,noatime,nodiratime,noikeep,nobarrier,allocsize=100M,attr2,largeio,inode64,swalloc     0 0`