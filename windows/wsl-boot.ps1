<#
.SYNOPSIS
  This script boots the default WSL machine with a pre-defined static IP.
.DESCRIPTION
  - This script updates the WSL machine with the pre-defined static IP on Linux side,
    and updates the NetAdapter 'vEthernet (WSL)' accordingly on Windows side.
  - This script also starts few Linux services (sshd, crond), so
    at every cron reboot, the Linux machine establishes the first ssh connection from GitBash (Windows) to WSL (Linux).
.NOTES
  - This script must Run As Administrator from a Windows PowerShell prompt.
  - Any WSL command starts the WSL machine if not started already, and
    creates the NetAdapter 'vEthernet (WSL)' if it does not exist already (Windows deletes it on Windows power down).
  - The command /boot/wsl-boot.sh updates the primary ip addr on Linux side, and starts few Linux services.
  - The crontab for user root runs @reboot ssh from GitBash to WSL, as it takes approx 16s to complete the very first time.
  - When connected to VPN, the DNS resolution fails with local DNS resolver.
  Note: You should connect all VMs in Hyper-V or VirtualBox to the VMSwitch 'WSL' too.
.LINK
  https://github.com/ocroz/wsl2-boot
#>

# wsl-boot.sh updates primary ip addr to 192.168.50.2 and starts few services on Linux side.
$WSLSubnetPrefix = "192.168.50"
$DnsAddress = $WSLSubnetPrefix + ".1"
if (isVpnConnected) {
  $DnsAddress = Get-DnsClientServerAddress -InterfaceAlias "Ethernet 2" -Family IPv4 | Foreach { echo $_.ServerAddresses[0] }
}
wsl -u root /boot/wsl-boot.sh $WSLSubnetPrefix $DnsAddress

# Update NetIPAddress if not match static WSL gateway IP.
$WSLGatewayIP = $WSLSubnetPrefix + ".1"
$WSLNetIPv4 = Get-NetAdapter 'vEthernet (WSL)' | Get-NetIPAddress | ? AddressFamily -Eq IPv4
if ($WSLNetIPv4 | Where-Object {$_.IPAddress -NotMatch $WSLGatewayIP}) {
  Remove-NetIPAddress -Confirm:$False -InterfaceIndex:$WSLNetIPv4.InterfaceIndex;
  New-NetIPAddress -IPAddress $WSLGatewayIP -PrefixLength 24 -InterfaceAlias 'vEthernet (WSL)';
}

# Update NetNat if not match static WSL subnet.
$WSLSubnet = $WSLSubnetPrefix + ".0/24"
$WSLNatName = "WSLNat"
$WSLNat = Get-NetNat | ? Name -Eq $WSLNatName
if ($WSLNat | Where-Object {$_.InternalIPInterfaceAddressPrefix -NotMatch $WSLSubnet}) {
  Remove-NetNat -Confirm:$False -Name:$WSLNat.Name;
  New-NetNat -Name $WSLNatName -InternalIPInterfaceAddressPrefix $WSLSubnet
}

# Delete other NetNat as Windows supports one NAT network only.
Get-NetNat | Where-Object {$_.Name -NotMatch $WSLNatName} | Foreach {Remove-NetNat -Confirm:$False -Name:$_.Name}
