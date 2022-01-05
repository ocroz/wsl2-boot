#!/bin/bash

function usage {
  echo -e "\n Syntax: $0 [-h|options]"
  echo -e "\n options:"
  echo -e "\t -p WslSubnetPrefix"
  echo -e "\t -g GatewayIP"
  echo -e "\t -i WslHostIP"
  echo -e "\t -n DnsServer"
  echo -e "\t -s DnsSearch"
  echo -e "\t -m NlMtuSize"
}

function check {
  # Fail if $2 is empty or starts with "-"
  if [ -z "$2" -o "${2:0:1}" == "-" ];then
    echo "$0: Option $1 needs a parameter"; usage; exit 1
  fi
}

# Optional parameters
while getopts ":hp:g:i:n:s:m:" option;do
  case $option in
    h) usage; exit;;
    p) check "-p" $OPTARG; WslSubnetPrefix=$OPTARG;;
    g) check "-g" $OPTARG; GatewayIP=$OPTARG;;
    i) check "-i" $OPTARG; WslHostIP=$OPTARG;;
    n) check "-n" $OPTARG; DnsServer=$OPTARG;;
    s) check "-s" $OPTARG; DnsSearch=$OPTARG;;
    m) check "-m" $OPTARG; NlMtuSize=$OPTARG;;
    \?) echo "$0: Invalid option $OPTARG"; usage; exit 1;;
    :) echo "$0: Option $OPTARG needs a parameter"; usage; exit 1;;
  esac
done

# Default values
[ -z "$WslSubnetPrefix" ] && WslSubnetPrefix="192.168.50"
[ -z "$GatewayIP" ] && GatewayIP="$WslSubnetPrefix.1"
[ -z "$WslHostIP" ] && WslHostIP="$WslSubnetPrefix.2"

echo Booting $(hostname -s) with WslSubnetPrefix=$WslSubnetPrefix, GatewayIP=$GatewayIP, WslHostIP=$WslHostIP ...
if [ -n "$DnsServer" ];then echo "With nameserver=$DnsServer ..."; fi
if [ -n "$DnsSearch" ];then echo "With search=$DnsSearch ..."; fi
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

# Patching nameserver and search for DNS requests, especially under VPN
if [ -n "$DnsServer" ];then echo "nameserver $DnsServer" > /etc/resolv.conf; fi
if [ -n "$DnsSearch" ];then echo "search $DnsSearch" >> /etc/resolv.conf; fi

# Start services
service ssh start
#service cron start

# Check configuration
echo WslHostIP = $(hostname -I)
grep -E "nameserver|search" /etc/resolv.conf
