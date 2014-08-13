#LVS

NAT DR TUN

RR WRR LC WLC LBLC DHASH SHASH

ipvsadm -A -t 172.16.100.1:80 -s rr

ipvsadm -Ln

ipvsadm -a -t 172.16.100.1:80 -r 192.168.1.100 -n -w 3

add tcp real nat weight


