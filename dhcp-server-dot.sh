#!/bin/bash
clear
versionrr=1.25
echo " EXTREME DOT - DHCP SERVER on NIC [UBUNTU]"
echo " MultiBalance VPN version"
echo

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

echo
echo "CHECKING REQUIRED APPS" 
echo
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
echo
echo "####################################################################### $versionrr #######"
echo
echo "check https://github.com/ExtremeDot/MultiBalance_VPN webpage and select your machine"
echo
        echo "Which VM Linux machine you are running? "
        echo "   1) Linux 01 - 10.1.10.x"
        echo "   2) Linux 02 - 10.2.10.x"
        echo "   3) Linux 03 - 10.3.10.x"
        echo "   4) Default Installation"
        until [[ $VMACHINE =~ ^[0-9]+$ ]] && [ "$VMACHINE" -ge 1 ] && [ "$VMACHINE" -le 4 ]; do
                read -rp "VMACHINE [1-4]: " -e -i 1 VMACHINE
	done
               


##################### SET BRIDGE INTERFACE CONFIGS
#### LINUX 1 #######
if [[ $VMACHINE == "1" ]]; then
echo " Linux 1 has selected"
echo
BRG_NAME="bridge1"
DHCP_IPV4=10.1.10.1
DHCP_IPV4_BASE=$(echo "${DHCP_IPV4}" | cut -d"." -f1-3)
DHCP_IPV4_ZERO=$(echo "${DHCP_IPV4}" | cut -d"." -f1-3)".0"
DHCP_IPV4_GW=$(echo "${DHCP_IPV4}" | cut -d"." -f1-3)".1"

WANIPSTATIC='null'

until [[ ${WANIPSTATIC} =~ ^([0-9]{1,3}\.){3} ]]; do
                read -rp "Define DHCP IP for ens33 network: " -e -i 192.168.2.101 WANIPSTATIC
done

fi

#### LINUX 2 #######
if [[ $VMACHINE == "2" ]]; then
echo " Linux 2 has selected"
echo
BRG_NAME="bridge1"
DHCP_IPV4=10.2.10.1
DHCP_IPV4_BASE=$(echo "${DHCP_IPV4}" | cut -d"." -f1-3)
DHCP_IPV4_ZERO=$(echo "${DHCP_IPV4}" | cut -d"." -f1-3)".0"
DHCP_IPV4_GW=$(echo "${DHCP_IPV4}" | cut -d"." -f1-3)".1"

WANIPSTATIC='null'

until [[ ${WANIPSTATIC} =~ ^([0-9]{1,3}\.){3} ]]; do
                read -rp "Define DHCP IP for ens33 network: " -e -i 192.168.2.102 WANIPSTATIC
done

fi

#### LINUX 3 #######
if [[ $VMACHINE == "3" ]]; then
echo " Linux 3 has selected"
echo
BRG_NAME="bridge1"
DHCP_IPV4=10.3.10.1
DHCP_IPV4_BASE=$(echo "${DHCP_IPV4}" | cut -d"." -f1-3)
DHCP_IPV4_ZERO=$(echo "${DHCP_IPV4}" | cut -d"." -f1-3)".0"
DHCP_IPV4_GW=$(echo "${DHCP_IPV4}" | cut -d"." -f1-3)".1"

WANIPSTATIC='null'

until [[ ${WANIPSTATIC} =~ ^([0-9]{1,3}\.){3} ]]; do
                read -rp "Define DHCP IP for ens33 network: " -e -i 192.168.2.103 WANIPSTATIC
done


fi

#### Default #######
if [[ $VMACHINE == "4" ]]; then
echo " Default Installation has selected"
echo
BRG_NAME="bridge1"
read -e -i "$BRG_NAME" -p "Set Bridge Interface Name: " input
BRG_NAME="${input:-$BRG_NAME}"

until [[ ${DHCP_IPV4} =~ ^([0-9]{1,3}\.){3} ]]; do
                read -rp "Define DHCP IP for $BRG_NAME: " -e -i 10.2.10.1 DHCP_IPV4
done

DHCP_IPV4_BASE=$(echo "${DHCP_IPV4}" | cut -d"." -f1-3)
DHCP_IPV4_ZERO=$(echo "${DHCP_IPV4}" | cut -d"." -f1-3)".0"
DHCP_IPV4_GW=$(echo "${DHCP_IPV4}" | cut -d"." -f1-3)".1"
fi

#####
WANIPSTATIC_GW=$(echo "${WANIPSTATIC}" | cut -d"." -f1-3)".1"
WANIPSTATIC_ZERO=$(echo "${WANIPSTATIC}" | cut -d"." -f1-3)".0"


#################### SET DNS FOR DHCP BRIDGE
# get data to changing DNS Settings
clear
echo
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
                read -rp "DNS [1-11]: " -e -i 1 DNS
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

############### DNS resolvers
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

########### DEFINE DHCP SERVER - CLIENTS IP RANGE:

IPRNG1=""
until [[ $IPRNG1 =~ ^((25[0-4]|2[0-4][0-9]|[01]?[0-9][0-9]?)){0}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$ && $IPRNG1 -gt 0 && $IPRNG1 -lt 201 ]] ; do
echo && echo "Define a number between 1-200 ."
read -rp "DHCP START IP: " -e -i 2 IPRNG1
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

############### Writing DHCP Server config
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

##############

cat << EOF > /etc/netplan/88-extremedot.yaml
network:
 version: 2
 renderer: networkd

 ethernets:

EOF

##### WAN SELECT - LINUX1
if [[ $VMACHINE == "1" ]]; then
echo && echo " Setting The Network Plan"
echo && echo " Select the Interface for [WAN] "
echo
ifconfig | grep flags | awk '{print $1}' | sed 's/:$//' | grep -Ev 'lo'
echo && echo

SERVER_NIC="ens33"
        until [[ ${WAN_NIC} =~ ^[a-zA-Z0-9_]+$ ]]; do
                read -rp "[WAN INTERFACE]: Enter interface name: " -e -i "${SERVER_NIC}" WAN_NIC
        done
fi


##### WAN SELECT - LINUX2
if [[ $VMACHINE == "2" ]]; then

echo && echo " Setting The Network Plan"
echo && echo " Select the Interface for [WAN] "
echo
ifconfig | grep flags | awk '{print $1}' | sed 's/:$//' | grep -Ev 'lo'
echo && echo

SERVER_NIC="ens33"
        until [[ ${WAN_NIC} =~ ^[a-zA-Z0-9_]+$ ]]; do
                read -rp "[WAN INTERFACE]: Enter interface name: " -e -i "${SERVER_NIC}" WAN_NIC
        done
fi

##### WAN SELECT - LINUX3
if [[ $VMACHINE == "3" ]]; then
echo && echo " Setting The Network Plan"
echo && echo " Select the Interface for [WAN] "
echo
ifconfig | grep flags | awk '{print $1}' | sed 's/:$//' | grep -Ev 'lo'
echo && echo

SERVER_NIC="ens33"
        until [[ ${WAN_NIC} =~ ^[a-zA-Z0-9_]+$ ]]; do
                read -rp "[WAN INTERFACE]: Enter interface name: " -e -i "${SERVER_NIC}" WAN_NIC
        done
fi


##### WAN SELECT - DEFAULT
if [[ $VMACHINE == "4" ]]; then

echo && echo " Setting The Network Plan"
echo && echo " Select the Interface for [WAN] "
echo
ifconfig | grep flags | awk '{print $1}' | sed 's/:$//' | grep -Ev 'lo'
echo && echo

SERVER_NIC="$(ifconfig | grep flags | awk '{print $1}' | sed 's/:$//' | grep -Ev 'lo' | head -1)"
        until [[ ${WAN_NIC} =~ ^[a-zA-Z0-9_]+$ ]]; do
                read -rp "[WAN INTERFACE]: Enter interface name: " -e -i "${SERVER_NIC}" WAN_NIC
        done
fi

###################
if [[ $VMACHINE == "4" ]]; then

cat <<EOF >> /etc/netplan/88-extremedot.yaml
# WAN INTERFACE
  $WAN_NIC:
   dhcp4: true
   optional: true

EOF

else

cat <<EOF >> /etc/netplan/88-extremedot.yaml
# WAN INTERFACE
  $WAN_NIC:
   addresses:
    - ${WANIPSTATIC}/24
   dhcp4: no
   routes:
    - to: default
      via: $WANIPSTATIC_GW
    - to: $WANIPSTATIC_ZERO/24
      via: $WANIPSTATIC_GW
      table: 101
   routing-policy:
    - from: $WANIPSTATIC_ZERO/24
      table: 101
EOF

fi

if [[ $VMACHINE == "4" ]]; then

echo " Select The First LAN CARD - DHCP SERVER"
echo 
ifconfig | grep flags | awk '{print $1}' | sed 's/:$//' | grep -Ev 'lo' | grep -Ev $WAN_NIC
echo && echo

SERVER_NIC="$(ifconfig | grep flags | awk '{print $1}' | sed 's/:$//' | grep -Ev 'lo' | grep -Ev $WAN_NIC | head -1)"
        until [[ ${LAN1_NIC} =~ ^[a-zA-Z0-9_]+$ ]]; do
                read -rp "[LAN1 INTERFACE]: Enter interface name: " -e -i "${SERVER_NIC}" LAN1_NIC
        done
LAN1NETWORK="10.41.40.1/24"

else

LAN1_NIC=ens34
LAN1NETWORK="10.41.40.1/24"

fi

cat <<EOF >> /etc/netplan/88-extremedot.yaml
# LAN1 INTERFACE
  $LAN1_NIC:
   dhcp4: no
   optional: true
   addresses:
   - $LAN1NETWORK

EOF


if [[ $VMACHINE == "4" ]]; then
while true; do
    read -rp "Do you want to add Second Lan NIC to Bridged DHCP server?[Yes or No]? :" -e -i "Yes"  yn
    case $yn in
        [Yy]* )
                echo " Select The Second LAN CARD - DHCP SERVER"
                echo ""
                ifconfig | grep flags | awk '{print $1}' | sed 's/:$//' | grep -Ev 'lo' | grep -Ev $WAN_NIC | grep -Ev $LAN1_NIC
                echo " "
                echo " "
                SERVER_NIC="$(ifconfig | grep flags | awk '{print $1}' | sed 's/:$//' | grep -Ev 'lo' | grep -Ev $WAN_NIC | grep -Ev $LAN1_NIC | head -1)"
                        until [[ ${LAN2_NIC} =~ ^[a-zA-Z0-9_]+$ ]]; do
                                read -rp "[LAN2 INTERFACE]: Enter interface name: " -e -i "${SERVER_NIC}" LAN2_NIC
                        done
echo && echo " Adding $LAN2_NIC to DHCP Server"

cat <<EOF >> /etc/netplan/88-extremedot.yaml
# LAN2 INTERFACE
  $LAN2_NIC:
   dhcp4: no
   optional: true
   addresses:
   - 10.42.40.1/24
# BRIDGE
 bridges:
  $BRG_NAME:
   dhcp4: no
   optional: true
   addresses:
   - $DHCP_IPV4_GW/24
   interfaces:
   - $LAN1_NIC
   - $LAN2_NIC
EOF

                break
                ;;
        [Nn]* )

echo " Skipping add another LAN card"


cat <<EOF >> /etc/netplan/88-extremedot.yaml
# BRIDGE
 bridges:
  $BRG_NAME:
   dhcp4: no
   optional: true
   addresses:
   - $DHCP_IPV4_GW/24
   interfaces:
   - $LAN1_NIC
EOF
                break
                ;;
        * ) echo "Please answer yes or no.";;
    esac
done

else

cat <<EOF >> /etc/netplan/88-extremedot.yaml
# BRIDGE
 bridges:
  $BRG_NAME:
   dhcp4: no
   optional: true
   addresses:
   - $DHCP_IPV4_GW/24
   interfaces:
   - $LAN1_NIC
EOF

fi


# FINISHING
netplan apply
sleep 2

############### ROUTING
echo " Routing ----------------------"
echo
mkdir -p /ExtremeDOT
touch /ExtremeDOT/dhcp_route.sh
echo && echo " Writing Default routing script"

# Select VPN Interface and Network
echo " Select VPN Service ..."
echo "--------------------------------------"
VPNINPUT_WG=`ifconfig | grep flags | awk '{print $1}' | sed 's/:$//' | grep -Ev 'lo*' | grep -Ev 'bri*' | grep -Ev 'ens*' | grep -Ev 't2s*'`
VPNINPUT_ENS=`ifconfig | grep flags | awk '{print $1}' | sed 's/:$//' | grep -Ev 'lo*' | grep -Ev 'bri*' | grep -Ev 'wg*' | grep -Ev 't2s*'`
VPNINPUT_V2RAY=`ifconfig | grep flags | awk '{print $1}' | sed 's/:$//' | grep -Ev 'lo*' | grep -Ev 'bri*' | grep -Ev 'wg*' | grep -Ev 'ens*'`
echo "--------------------------------------"
VPNSERVPROVIDER=null
echo
        echo "Which VPN Service you are running? "
        echo "   1) Wireguard - [$VPNINPUT_WG]"
        echo "   2) V2Ray - [$VPNINPUT_V2RAY]"
        echo "   3) System - [$VPNINPUT_ENS]"
        echo "   4) Custom Installation"
until [[ $VPNSERVPROVIDER =~ ^[0-9]+$ ]] && [ "$VPNSERVPROVIDER" -ge 1 ] && [ "$VPNSERVPROVIDER" -le 4 ]; do
                read -rp "VPNSERVPROVIDER [1-4]: " -e -i 1 VPNSERVPROVIDER;
done

if [[ $VPNSERVPROVIDER == "1" ]]; then
echo " WireGuard Selected"
VPNIPINTERFACE=$VPNINPUT_WG
fi

if [[ $VPNSERVPROVIDER == "2" ]]; then
echo " Tun2Socks - V2ray Selected"
VPNIPINTERFACE=$VPNINPUT_V2RAY
fi

if [[ $VPNSERVPROVIDER == "3" ]]; then
echo " System Selected"
VPNIPINTERFACE=null
echo " select $VPNINPUT_ENS"

ifconfig | grep flags | awk '{print $1}' | sed 's/:$//' | grep -Ev 'lo*' | grep -Ev 'bri*' | grep -Ev 'wg*' | grep -Ev 't2s*'

VPNINPUT_ENS=`ifconfig | grep flags | awk '{print $1}' | sed 's/:$//' | grep -Ev 'lo*' | grep -Ev 'bri*' | grep -Ev 'wg*' | grep -Ev 't2s*' | head -1`
WAN_NICES=''
SERVER_NICES=$VPNINPUT_ENS

        until [[ ${WAN_NICES} =~ ^[a-zA-Z0-9_]+$ ]]; do
                read -rp "[VPN INTERFACE]: Enter interface name: " -e -i "${SERVER_NICES}" WAN_NICES
        done
VPNIPINTERFACE=$WAN_NICES
fi

if [[ $VPNSERVPROVIDER == "4" ]]; then
echo " Custom Selected"
VPNIPINTERFACE=null
        until [[ ${WAN_NICES2} =~ ^[a-zA-Z0-9_]+$ ]]; do
                read -rp "[VPN INTERFACE]: Enter interface name: " -e -i "${SERVER_NICES}" WAN_NICES2
        done
VPNIPINTERFACE=$WAN_NICES2
fi

###################
####IP finder
#ip -f inet addr show wg0 | awk '/inet / {print $2}'
#ifconfig wg0 | awk '/inet / {print $2}'
###########


cat <<EOF > /ExtremeDOT/dhcp_route.sh
#!/bin/bash
sysctl -w net.ipv4.ip_forward=1
sysctl -p
/usr/bin/systemctl start iptables
sleep 3

VPNNETNAME=$VPNIPINTERFACE
VPN_TABLE=900
VPNIP=`ifconfig $VPNIPINTERFACE | awk '/inet / {print $2}'`
sleep 1
VPNIP_GW=$(echo `ifconfig $VPNIPINTERFACE | awk '/inet / {print $2}'` | cut -d "." -f1-3).1
VPNIP_NETWORK=$(echo `ifconfig $VPNIPINTERFACE | awk '/inet / {print $2}'` | cut -d "." -f1-3).0/24
#VPNIP_NETWORK=$(echo "$VPNIP" | cut -d"." -f1-3)".0/24"
BRIDGE_NAME=$BRG_NAME
BRIDGE_NETWORK=$(echo "$DHCP_IPV4_GW" | cut -d"." -f1-3).0/24
#BRIDGE_NETWORK="$DHCP_IPV4_GW/24"

/sbin/ip route add \$BRIDGE_NETWORK dev \$BRIDGE_NAME table \$DEF_TABLE
sleep 1
/sbin/ip route add \$VPNIP_NETWORK dev \$VPNNETNAME table \$DEF_TABLE
sleep 1
/sbin/ip route add default via \$VPNIP_GW dev \$VPNNETNAME table \$DEF_TABLE
sleep 2

#/sbin/ip route show table \$DEF_TABLE

/sbin/ip rule add iif \$VPNNETNAME lookup \$DEF_TABLE
sleep 1
/sbin/ip rule add iif \$BRIDGE_NAME lookup \$DEF_TABLE
sleep 2

#/sbin/ip rule | grep \$DEF_TABLE

/sbin/iptables -t nat -A POSTROUTING -s \$BRIDGE_NETWORK -o \$VPNNETNAME -j MASQUERADE

EOF
########################

sleep 2
chmod +x /ExtremeDOT/dhcp_route.sh
echo "/ExtremeDOT/dhcp_route.sh is saved to manual route"

echo " Add routing to Startup"
crontab -l | { cat; echo "@reboot sleep 10 && sudo bash /ExtremeDOT/dhcp_route.sh" ; } | crontab -
