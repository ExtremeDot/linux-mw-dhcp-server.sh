#!/bin/bash
echo " EXTREME DOT - DHCP SERVER on NIC [UBUNTU]"

# ROOT CONDITIONS
function isRoot() {
        if [ "$EUID" -ne 0 ]; then
                return 1
        fi
}

if ! isRoot; then
        echo "Sorry, you need to run this as root"
        exit 1
fi
clear
echo ""
echo "CHECKING REQUIRED APPS" 
echo ""
# check if DHCPD is installed
status="$(dpkg-query -W --showformat='${db:Status-Status}' "isc-dhcp-server" 2>&1)"
if [ ! $? = 0 ] || [ ! "$status" = installed ]; then
echo " - - - Installing DHCP Server"
apt-get install -y isc-dhcp-server
else
echo " DHCP Server =            OK"
fi
status="$(dpkg-query -W --showformat='${db:Status-Status}' "bridge-utils" 2>&1)"
if [ ! $? = 0 ] || [ ! "$status" = installed ]; then
echo " - - - Installing Bridging Tools"
apt-get install -y bridge-utils
else
echo " Bridging Tool =          OK"
fi

status="$(dpkg-query -W --showformat='${db:Status-Status}' "network-manager" 2>&1)"
if [ ! $? = 0 ] || [ ! "$status" = installed ]; then
echo " - - - Installing Network Manager"
apt-get install -y network-manager
else
echo " Network Manager =        OK"
fi

status="$(dpkg-query -W --showformat='${db:Status-Status}' "iptables-persistent" 2>&1)"
if [ ! $? = 0 ] || [ ! "$status" = installed ]; then
echo " - - - Installing IPTABLES Service"
apt-get install -y iptables-persistent
else
echo " IP TABLE Tools =         OK"
fi

status="$(dpkg-query -W --showformat='${db:Status-Status}' "net-tools" 2>&1)"
if [ ! $? = 0 ] || [ ! "$status" = installed ]; then
echo " - - - Installing Networking Tools"
apt-get install -y net-tools
else
echo " Networking Tools =       OK"
fi

# SET BRIDGE INTERFACE CONFIGS
echo ""
BRG_NAME="bridge1"
read -e -i "$BRG_NAME" -p "Set Bridge Interface Name: " input
BRG_NAME="${input:-$BRG_NAME}"

until [[ ${DHCP_IPV4} =~ ^([0-9]{1,3}\.){3} ]]; do
                read -rp "Define DHCP IP for $BRG_NAME: " -e -i 10.2.10.1 DHCP_IPV4
done

DHCP_IPV4_BASE=$(echo "${DHCP_IPV4}" | cut -d"." -f1-3)
DHCP_IPV4_ZERO=$(echo "${DHCP_IPV4}" | cut -d"." -f1-3)".0"
DHCP_IPV4_GW=$(echo "${DHCP_IPV4}" | cut -d"." -f1-3)".1"

# SET DNS FOR DHCP BRIDGE
# get data to changing DNS Settings
echo ""
        echo "What DNS resolvers do you want to use with the VPN?"
        echo "   1) Cloudflare (Anycast: worldwide)"
        echo "   2) Quad9 (Anycast: worldwide)"
        echo "   3) Quad9 uncensored (Anycast: worldwide)"
        echo "   4) FDN (France)"
        echo "   5) DNS.WATCH (Germany)"
        echo "   6) OpenDNS (Anycast: worldwide)"
        echo "   7) Google (Anycast: worldwide)"
        echo "   8) Yandex Basic (Russia)"
        echo "   9) AdGuard DNS (Anycast: worldwide)"
        echo "   10) NextDNS (Anycast: worldwide)"
        #echo "   11) SKIP, No change"
	echo "   11) Custom"
        until [[ $DNS =~ ^[0-9]+$ ]] && [ "$DNS" -ge 1 ] && [ "$DNS" -le 11 ]; do
                read -rp "DNS [1-11]: " -e -i 9 DNS
                if [[ $DNS == "11" ]]; then
                        until [[ $DNS1 =~ ^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$ ]]; do
                                read -rp "Primary DNS: " -e DNS1
                        done
                        until [[ $DNS2 =~ ^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$ ]]; do
                                read -rp "Secondary DNS (optional): " -e DNS2
                                if [[ $DNS2 == "" ]]; then
                                        break
                                fi
                        done
                fi
        done

# DNS resolvers
DEST_RESOLV1=""
DEST_RESOLV2=""
case $DNS in
        1) # Cloudflare
		DEST_RESOLV1=1.1.1.1
		DEST_RESOLV2=1.0.0.1
                ;;
        2) # Quad9
		DEST_RESOLV1=9.9.9.9
		DEST_RESOLV2=149.112.112.112
                ;;
        3) # Quad9 uncensored
        DEST_RESOLV1=9.9.9.10
		DEST_RESOLV2=149.112.112.10
                ;;
        4) # FDN
		DEST_RESOLV1=80.67.169.40
		DEST_RESOLV2=80.67.169.12
                ;;
        5) # DNS.WATCH
		DEST_RESOLV1=84.200.69.80
		DEST_RESOLV2=84.200.70.40
                ;;
        6) # OpenDNS
		DEST_RESOLV1=208.67.222.222
		DEST_RESOLV2=208.67.220.220
                ;;
        7) # Google
		DEST_RESOLV1=8.8.8.8
		DEST_RESOLV2=8.8.4.4
                ;;
	8) # Yandex Basic
		DEST_RESOLV1=77.88.8.8
		DEST_RESOLV2=77.88.8.1
                ;;
        9) # AdGuard DNS
		DEST_RESOLV1=94.140.14.14
		DEST_RESOLV2=94.140.15.15
                ;;
        10) # NextDNS
		DEST_RESOLV1=45.90.28.167
		DEST_RESOLV2=45.90.30.167
                ;;
	    11) # Custom DNS
		DEST_RESOLV1=$DNS1
		DEST_RESOLV2=8.8.8.8
		  if [[ $DNS2 != "" ]]; then
        DEST_RESOLV2=$DNS2
  		fi
                ;;
esac

# DEFINE DHCP SERVER - CLIENTS STARTING IP:
IPRNG1=""
until [[ $IPRNG1 =~ ^((25[0-4]|2[0-4][0-9]|[01]?[0-9][0-9]?)){0}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$ && $IPRNG1 -gt 2 && $IPRNG1 -lt 201 ]] ; do
echo ""
echo "Define a number between 3-200 ."
read -rp "DHCP START IP: " -e -i 10 IPRNG1
done
IPRNG2=""
until [[ $IPRNG2 =~ ^((25[0-4]|2[0-4][0-9]|[01]?[0-9][0-9]?)){0}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$ && $IPRNG2 -gt $IPRNG1 ]] ; do
echo ""
echo "DHCP START IP RANGE= $IPRNG1"
END_IP_REC=$((30 + $IPRNG1))
if [ $END_IP_REC -gt 254 ]
then
END_IP_REC=254
fi
echo "Define +30 number from DHCP Starting IP."
echo "It relates to how much clients will connect to your server."
read -rp "DHCP END IP: [ $END_IP_REC ~ 254 ] " -e -i $END_IP_REC IPRNG2
done

cat <<EOF > /etc/dhcp/dhcpd.conf

subnet $DHCP_IPV4_ZERO netmask 255.255.255.0 {
  range $DHCP_IPV4_BASE.$IPRNG1 $DHCP_IPV4_BASE.$IPRNG2;
  option domain-name-servers $DHCP_IPV4_GW,$DEST_RESOLV1,$DEST_RESOLV2;
  option domain-name home;
  option subnet-mask 255.255.255.0;
  option routers $DHCP_IPV4_GW;
  option broadcast-address $DHCP_IPV4_BASE.255;
  default-lease-time 3600;
  max-lease-time 7200;
}

EOF

cat <<EOF > /etc/default/isc-dhcp-server

INTERFACESv4="$BRG_NAME"
INTERFACESv6="$BRG_NAME"

EOF

cat <<EOF > /etc/netplan/01-netcfg.yaml
network:
 version: 2
 renderer: networkd

 ethernets:

EOF

echo ""
echo " Setting The Network Plan"
echo ""

echo " Select the Interface for [WAN] "
echo ""
ifconfig | grep flags | awk '{print $1}' | sed 's/:$//' | grep -Ev 'lo'
echo " "
echo " "
SERVER_NIC="$(ifconfig | grep flags | awk '{print $1}' | sed 's/:$//' | grep -Ev 'lo' | head -1)"
        until [[ ${WAN_NIC} =~ ^[a-zA-Z0-9_]+$ ]]; do
                read -rp "[WAN INTERFACE]: Enter interface name: " -e -i "${SERVER_NIC}" WAN_NIC
        done

cat <<EOF >> /etc/netplan/01-netcfg.yaml
# WAN INTERFACE
  $WAN_NIC:
   dhcp4: true

EOF

echo " Select The First LAN CARD - DHCP SERVER"
echo ""
ifconfig | grep flags | awk '{print $1}' | sed 's/:$//' | grep -Ev 'lo' | grep -Ev '$WAN_NIC'
echo " "
echo " "
SERVER_NIC="$(ifconfig | grep flags | awk '{print $1}' | sed 's/:$//' | grep -Ev 'lo' | grep -Ev '$WAN_NIC' | head -1)"
        until [[ ${LAN1_NIC} =~ ^[a-zA-Z0-9_]+$ ]]; do
                read -rp "[LAN1 INTERFACE]: Enter interface name: " -e -i "${SERVER_NIC}" LAN1_NIC
        done

cat <<EOF >> /etc/netplan/01-netcfg.yaml

# LAN1 INTERFACE
  $LAN1_NIC:
   dhcp4: no
   addresses:
   - 10.41.40.1/24
# BRIDGE
 bridges:
  $BRG_NAME:
   dhcp4: no
   addresses:
   - $DHCP_IPV4_GW/24
   interfaces:
   - $LAN1_NIC
EOF

while true; do
    read -rp "Do you want to another Lan NIC to Bridged DHCP server?[Yes or No]? :" -e -i "Yes"  yn
    case $yn in
        [Yy]* )
                echo " Select The Second LAN CARD - DHCP SERVER"
                echo ""
                ifconfig | grep flags | awk '{print $1}' | sed 's/:$//' | grep -Ev 'lo' | grep -Ev '$WAN_NIC' | grep -Ev '$LAN1_NIC'
                echo " "
                echo " "
                SERVER_NIC="$(ifconfig | grep flags | awk '{print $1}' | sed 's/:$//' | grep -Ev 'lo' | grep -Ev '$WAN_NIC' | grep -Ev '$LAN1_NIC' | head -1)"
                        until [[ ${LAN2_NIC} =~ ^[a-zA-Z0-9_]+$ ]]; do
                                read -rp "[LAN2 INTERFACE]: Enter interface name: " -e -i "${SERVER_NIC}" LAN2_NIC
                        done
echo ""
echo " Adding $LAN2_NIC to DHCP Server"
cat <<EOF >> /etc/netplan/01-netcfg.yaml
   - $LAN2_NIC

# LAN2 INTERFACE
  $LAN2_NIC:
   dhcp4: no
   addresses:
   - 10.42.40.1/24

EOF

                break
                ;;
        [Nn]* )
                echo " Skipping add another LAN card"
                break
                ;;
        * ) echo "Please answer yes or no.";;
    esac
done

# FINISHING
netplan apply
sleep 2

mkdir -p /ExtremeDOT
touch /ExtremeDOT/dhcp_route.sh
echo ""
echo " Writing Default routing script"
cat <<EOF > /ExtremeDOT/dhcp_route.sh
#!/bin/bash
sysctl -w net.ipv4.ip_forward=1
sysctl -p
/usr/bin/systemctl start iptables
sleep 3
# need to be updated
DEF_IPV4_ZERO=192.168.2.0
DEF_IPV4_GW=192.168.2.1
DEF_TABLE=900
/sbin/route add $DHCP_IPV4_ZERO/24 dev $BRG_NAME table \$DEF_TABLE
sleep 1
/sbin/route add \$DEF_IPV4_ZERO/24 dev $WAN_NIC table \$DEF_TABLE
sleep 1
/sbin/route add default via \$DEF_IPV4_GW dev $WAN_NIC table \$DEF_TABLE
sleep 2
#/sbin/ip route show table \$DEF_TABLE
/sbin/ip rule add iif $WAN_NIC lookup \$DEF_TABLE
sleep 1
/sbin/ip rule add iif $BRG_NAME lookup \$DEF_TABLE
sleep 2
#/sbin/ip rule | grep \$DEF_TABLE
/sbin/iptables -t nat -A POSTROUTING -s \$DHCP_IPV4_ZERO/24 -o $WAN_NIC -j MASQUERADE

EOF

sleep 2
chmod +x /ExtremeDOT/dhcp_route.sh
echo "/ExtremeDOT/dhcp_route.sh is saved to manual route"

echo " Add routing to Startup"

sudo crontab -l | { cat; echo "@reboot sleep 10 && sudo bash /ExtremeDOT/dhcp_route.sh" ; } | crontab -
