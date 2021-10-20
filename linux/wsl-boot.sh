#!/bin/bash

# Optional parameters
# $1 is the IPPrefix which defaults to "192.168.50"
# $2 is the DNS nameserver which defaults to $IPPrefix.1

IPPrefix="$(if [ -n "$1" ];then echo $1; else echo "192.168.50"; fi)"
DnsAddress="$(if [ -n "$2" ];then echo $2; else echo $IPPrefix.1; fi)"
echo Booting $(hostname -s) with IPPrefix=$IPPrefix and DnsAddress=$DnsAddress ...

# Run this script as root at boot to set static IP
ip addr del $(ip addr show eth0 | grep 'inet\b' | awk '{print $2}' | head -n 1) dev eth0
ip addr add $IPPrefix.2/24 broadcast $IPPrefix.255 dev eth0
ip route add 0.0.0.0/0 via $IPPrefix.1 dev eth0
echo "nameserver $DnsAddress" > /etc/resolv.conf

# Start services
service ssh start
service cron start
