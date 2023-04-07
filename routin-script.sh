#!/bin/bash
sleep 15
echo "1" > /proc/sys/net/ipv4/ip_forward
sysctl -w net.ipv4.ip_forward=1
sysctl -p
/usr/bin/systemctl start iptables
sleep 3

###################################################
# Update This Values ###################
VPNNETNAME=CloudflareWARP
BRIDGE_NAME=bridge1
VPN_TABLE=900
# FINISH ##############################
###################################################
## DONT TOUCH BELOW ###############################
DEF_TABLE=$VPN_TABLE
# Automated  VPN IP
VPNIP=$(ip -4 addr | grep $VPNNETNAME | sed -ne 's|^.* inet \([^/]*\)/.* scope global.*$|\1|p')
sleep 1
VPN_IP_BASE=$(echo "$VPNIP" | cut -d "." -f1-3)
VPNIP_GW=$(echo "$VPN_IP_BASE".1)
VPNIP_NETWORK=$(echo "$VPN_IP_BASE".0/24)

# Automated  Bridge IP
BRIDGEIP=$(ip -4 addr | grep $BRIDGE_NAME | sed -ne 's|^.* inet \([^/]*\)/.* scope global.*$|\1|p')
sleep 1
BRIDGE_IP_BASE=$(echo "$BRIDGEIP" | cut -d "." -f1-3)
BRIDGE_GW=$(echo "$BRIDGE_IP_BASE".1)
BRIDGE_NETWORK=$(echo "$BRIDGE_IP_BASE".0/24)

#### Automated Routing PART
sleep 15
/sbin/ip route add $BRIDGE_NETWORK dev $BRIDGE_NAME table $DEF_TABLE
sleep 1
/sbin/ip route add $VPNIP_NETWORK dev $VPNNETNAME table $DEF_TABLE
sleep 1
/sbin/ip route add default via $VPNIP_GW dev $VPNNETNAME table $DEF_TABLE
sleep 2

#/sbin/ip route show table $DEF_TABLE
/sbin/ip rule add iif $VPNNETNAME lookup $DEF_TABLE
sleep 1
/sbin/ip rule add iif $BRIDGE_NAME lookup $DEF_TABLE
sleep 2

#/sbin/ip rule | grep $DEF_TABLE
/sbin/iptables -t nat -A POSTROUTING -s $BRIDGE_NETWORK -o $VPNNETNAME -j MASQUERADE
