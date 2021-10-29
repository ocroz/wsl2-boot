# Boot WSL2 machine with fixed IP

Param(
  $WslSubnetPrefix = "192.168.50",
  $distribution = $null,
  [IPAddress] $ip = $null
)
$Name = "WSL"
$WslSubnet = "$WSLSubnetPrefix.0/24"
$GatewayIP = "$WslSubnetPrefix.1"
$WslHostIP = "$WslSubnetPrefix.2"; if ($ip) { $WslHostIP = $ip.ToString() }

# General information
if (-Not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')) {
  Throw "Please run this script with elevated permission (Run As Administrator)"
}
$d = $null; $distro = "default"; if ($distribution) { $d = "-d"; $distro = $distribution }
Write-Host "Booting $distro distribution with WslSubnetPrefix $WslSubnetPrefix, WslHostIP $WslHostIP ..."

# Load HnsEx
$CurrentPath = Split-Path $script:MyInvocation.MyCommand.Path -Parent
. $(Join-Path -Path $CurrentPath -ChildPath "HnsEx.ps1")

# Check any existing WSL network
$wslNetwork = Get-HnsNetwork | Where-Object { $_.Name -eq $Name }

# Create or recreate WSL network if necessary
if ($wslNetwork -eq $null -Or $wslNetwork.Subnets.AddressPrefix -ne $WslSubnet) {
  # To cleanly delete the VM Switch named WSL along with WSL Network (see: Get-VMSwitch -Name WSL)
  # and to assign correct DNS nameserver after WSL Network is recreated and WSL host is restarted:
  # - Cleanly shutdown all WSL hosts, and
  # - Cleanly stop all Hyper-V VMs using WSL VMSwitch too
  Write-Host "Stopping all WSL hosts and all Hyper-V VMs connected to VMSwitch $Name ..."
  wsl --shutdown
  Get-VM | ? { $_.State -eq 'Running' } | Get-VMNetworkAdapter | ? SwitchName -eq $Name | Foreach { Stop-VM -Name $_.VMName }

  # Delete existing network
  Write-Host "Deleting existing WSL network and other conflicting NAT network ..."
  $wslNetwork | Remove-HnsNetwork

  # Delete conflicting NetNat
  $wslNetNat = Get-NetNat | Where-Object {$_.InternalIPInterfaceAddressPrefix -Match $AddressPrefix}
  $wslNetNat | Foreach {Remove-NetNat -Confirm:$False -Name:$_.Name}

  # Create new WSL network
  New-HnsNetwork -Name $Name -AddressPrefix $WslSubnet -GatewayAddress $GatewayIP # -Debug
}

# wsl-boot.sh updates primary ip addr to $WslHostIP and starts few services on Linux side.
wsl $d $distribution -u root /boot/wsl-boot.sh $WslSubnetPrefix $WslHostIP $GatewayIP

# Switch all misconfigured Hyper-V VMs to newly created Virtual VMSwitch 'WSL'
Write-Host "Switching all misconfigured Hyper-V VMs to newly created VMSwitch $Name ..."
Get-VM | Get-VMNetworkAdapter | ? SwitchName -eq $null | Connect-VMNetworkAdapter -SwitchName $Name

# Restart all VMs which failed to start due to network misconfiguration
# as Virtual switch 'WSL' got deleted at Windows power down
Get-VM | ? State -Eq Saved | Start-VM
