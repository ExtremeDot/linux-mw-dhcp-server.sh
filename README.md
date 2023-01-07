# linux-mw-dhcp-server.sh
It will run DHCP Server for NICs.

/etc/dhcp/dhcpd.conf 
                                                                                           
subnet 40.10.2.0 netmask 255.255.255.0 {
  range 40.10.2.10 40.10.2.100;
  option domain-name-servers 40.10.2.1,1.1.1.1,8.8.8.8;
  option domain-name home;
  option subnet-mask 255.255.255.0;
  option routers 40.10.2.1;
  option broadcast-address 40.10.2.255;
  default-lease-time 600;
  max-lease-time 7200;
}

systemctl restart isc-dhcp-server
systemctl status isc-dhcp-server
journalctl _PID=


nano /etc/default/isc-dhcp-server

INTERFACESv4="br0"
INTERFACESv6="br0"


nano /etc/netplan/01-netcfg.yaml
network:
 version: 2
 renderer: networkd

 ethernets:

#- FISRT
  eno1:
   dhcp4: true

#- SECOND
  enp1s0:
   dhcp4: no
   addresses:
   - 10.11.70.2/24
   
#- THIRD
  enp3s0:
   dhcp4: no
   addresses:
   - 10.12.70.2/24

#- BRIDGE
 bridges:
  br0:
   interfaces:
   - enp1s0
   - enp3s0
   dhcp4: no
   addresses:
   - 40.10.2.1/24

	
	
netplan apply

sudo sysctl -w net.ipv4.ip_forward=1
sudo sysctl -p

/usr/bin/systemctl start iptables


/sbin/ip rule | grep 100

ip route add 40.10.2.0/24 dev br0 table 100
ip route add 192.168.2.0/24 dev eno1 table 100
ip route add default via 192.168.2.1 dev eno1 table 100

ip route show table 100

ip rule add iif br0 lookup 100
ip rule add iif eno1 lookup 100

/sbin/iptables -t nat -A POSTROUTING -s 40.10.2.0/24 -o eno1 -j MASQUERADE

default via 40.10.2.1 dev br0 proto static metric 10
