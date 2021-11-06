#!/bin/bash

# Optional parameters
# $1 is the WslSubnetPrefix which defaults to "192.168.50"
# $2 is the WslHostIP which defaults to "$WslSubnetPrefix.2"
# $3 is the GatewayIP which defaults to "$WslSubnetPrefix.1"
# $4 is the DnsServer which defaults to "" (keep configured nameserver)
# $5 if the NlMtuSize which defaults to "" (keep configured MTU)

WslSubnetPrefix="$(if [ -n "$1" ];then echo $1; else echo "192.168.50"; fi)"
WslHostIP="$(if [ -n "$2" ];then echo $2; else echo "$WslSubnetPrefix.2"; fi)"
GatewayIP="$(if [ -n "$3" ];then echo $3; else echo "$WslSubnetPrefix.1"; fi)"
DnsServer="$(if [ -n "$4" ];then echo $4; else echo ""; fi)"
NlMtuSize="$(if [ -n "$5" ];then echo $5; else echo ""; fi)"
echo Booting $(hostname -s) with WslSubnetPrefix=$WslSubnetPrefix, WslHostIP=$WslHostIP, GatewayIP=$GatewayIP ...
if [ -n "$DnsServer" ];then echo "With nameserver=$DnsServer ..."; fi
if [ -n "$NlMtuSize" ];then echo "With mtu=$NlMtuSize ..."; fi

# Debug logging
log=/var/log/wsl-boot.log
mkdir -p $(dirname $log)
dev=eth0
currentIP=$(ip addr show $dev | grep 'inet\b' | awk '{print $2}' | head -n 1)
echo "Original IP = $currentIP" >$log

# Run this script as root at boot to set static IP
ip addr del $currentIP dev $dev
ip addr add $WslHostIP/24 broadcast $WslSubnetPrefix.255 dev $dev
ip route add 0.0.0.0/0 via $GatewayIP dev $dev

# Patching MTU, especially under VPN
if [ -n "$NlMtuSize" ];then ip link set dev $dev mtu $NlMtuSize; fi

# Patching nameserver for DNS requests, especially under VPN
if [ -n "$DnsServer" ];then echo "nameserver $DnsServer" > /etc/resolv.conf; fi

# Start services
service ssh start
#service cron start

# Check configuration
echo WslHostIP = $(hostname -I)
grep nameserver /etc/resolv.conf
