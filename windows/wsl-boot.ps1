# Boot WSL2 machine with fixed IP

Param(
  $WslSubnetPrefix = "192.168.50",
  $distribution = $null
)
$Name = "WSL"
$WslSubnet = "$WSLSubnetPrefix.0/24"
$GatewayIP = "$WslSubnetPrefix.1"
$WslHostIP = "$WslSubnetPrefix.2"
$DnsServer = "$GatewayIP"

$d = $null; $distro = "default"; if ($distribution) { $d = "-d"; $distro = $distribution }
Write-Host Booting $distro distribution with WslSubnetPrefix $WslSubnetPrefix ...

# Load HnsEx
$CurrentPath = Split-Path $script:MyInvocation.MyCommand.Path -Parent
. $(Join-Path -Path $CurrentPath -ChildPath "HnsEx.ps1")

# Check any existing WSL network
$wslNetwork = Get-HnsNetwork | Where-Object { $_.Name -eq $Name }

$newNetwork = $false
if ($wslNetwork -eq $null) {
  Write-Host "Creating WSL network ..."
  $newNetwork = $true
} elseif ($wslNetwork.Subnets.AddressPrefix -ne $AddressPrefix) {
  Write-Host "Re-creating WSL network ..."
  $wslNetwork | Remove-HnsNetwork # Delete existing network
  $newNetwork = $true
}

if ($newNetwork) {
  # Delete conflicting NetNat first
  $wslNetNat = Get-NetNat | Where-Object {$_.InternalIPInterfaceAddressPrefix -Match $AddressPrefix}
  $wslNetNat | Foreach {Remove-NetNat -Confirm:$False -Name:$_.Name}

  # Create new WSL network
  New-HnsNetwork -Name $Name -AddressPrefix $WslSubnet -GatewayAddress $GatewayIP

  # wsl-boot.sh updates primary ip addr to $WslHostIP and starts few services on Linux side.
  wsl $d $distribution -u root /boot/wsl-boot.sh $WslSubnetPrefix $WslHostIP $GatewayIP $DnsServer

  # Switch all VMs to newly created Virtual switch 'WSL'
  Get-VM | Get-VMNetworkAdapter | ? SwitchName -eq $null | Connect-VMNetworkAdapter -SwitchName WSL

  # Restart all VMs which failed to start due to network misconfiguration
  # as Virtual switch 'WSL' got deleted at Windows power down
  Get-VM | ? State -Eq Saved | Start-VM
}
