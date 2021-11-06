<#
.SYNOPSIS
  Boot WSL2 machine with fixed IP.
.DESCRIPTION
  - This script create or recreate the WSL network on Windows side,
    and updates the WSL machine with the pre-defined static IP on Linux side.
  - This script manages other Hyper-V VMs connected to WSL network too.
  - This script also starts few Linux services (sshd).
.NOTES
  - This script must Run As Administrator from a Windows PowerShell prompt,
    or from the bat file executed with elevated permission (Run As Administrator).
  - Any WSL command starts the WSL machine if not started already, and
    creates the NetAdapter 'vEthernet (WSL)' if it does not exist already (Windows deletes it on Windows power down).
    However this script creates the NetAdapter first, so WSL will re-use it.
  - The command /boot/wsl-boot.sh updates the primary ip addr on Linux side, and starts few Linux services.
  - Windows assigns the correct DNS nameserver if everything happened in the correct order
    i.e. WSL2 lightweight utility virtual machine is down and all Hyper-V VMs using WSL VMSwitch are down too
    before WSL network is recreated.
  - The DNS resolution works in any situation however you are connected to Internet, and with or without VPN.
  Note: You should connect all VMs in Hyper-V to the VMSwitch 'WSL' too.
.LINK
  https://github.com/ocroz/wsl2-boot
#>

[CmdletBinding()] Param(
  [parameter(Mandatory=$false)] [String] $WslSubnetPrefix = "192.168.50",
  [parameter(Mandatory=$false)] [String] $distribution = $null,
  [parameter(Mandatory=$false)] [IPAddress] $ip = $null,
  [parameter(Mandatory=$false)] [Bool] $force = $False,
  [parameter(Mandatory=$false)] [Bool] $reboot = $False
)
$Name = "WSL"
$WslSubnet = "$WSLSubnetPrefix.0/24"
$GatewayIP = "$WslSubnetPrefix.1"
$WslHostIP = "$WslSubnetPrefix.2"; if ($ip) { $WslHostIP = $ip.ToString() }
if ($PSBoundParameters['Debug']) { $DebugPreference = "Continue" }

# General information
if (-Not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')) {
  Throw "Please run this script with elevated permission (Run As Administrator)"
}
$d = $null; $distro = "default"; if ($distribution) { $d = "-d"; $distro = $distribution }
Write-Host "Booting $distro distribution with WslSubnetPrefix $WslSubnetPrefix, WslHostIP $WslHostIP ..."

# Load HnsEx and VpnEx
$CurrentPath = Split-Path $script:MyInvocation.MyCommand.Path -Parent
. $(Join-Path -Path $CurrentPath -ChildPath "HnsEx.ps1")
. $(Join-Path -Path $CurrentPath -ChildPath "VpnEx.ps1")

function Start-WslBoot() {
  Write-Debug "Start-WslBoot() in debug mode"

  # Check any existing WSL network
  $wslNetwork = Get-HnsNetwork | Where-Object { $_.Name -eq $Name }

  # Create or recreate WSL network if necessary
  if ($force -Or $wslNetwork -eq $null -Or $wslNetwork.Subnets.AddressPrefix -ne $WslSubnet) {
    # To cleanly delete the VMSwitch named WSL along with WSL Network (see: Get-VMSwitch -Name WSL)
    # and to assign correct DNS nameserver after WSL Network is recreated and WSL host is restarted:
    # - Cleanly shutdown all WSL hosts, and
    # - Cleanly stop all Hyper-V VMs using WSL VMSwitch too
    Write-Host "Stopping all WSL hosts and all Hyper-V VMs connected to VMSwitch $Name ..."
    wsl --shutdown
    $wslVMs = Get-VM | ? { $_.State -eq 'Running' } | Get-VMNetworkAdapter | ? SwitchName -eq $Name
    $wslVMs | Foreach { Stop-VM -Name $_.VMName }

    # Delete existing network
    Write-Host "Deleting existing WSL network and other conflicting NAT network ..."
    $wslNetwork | Remove-HnsNetwork

    # Destroy WSL network may fail if it happened in the wrong order like if it was done manually
    if (Get-VMSwitch -Name $Name -ea "SilentlyContinue") {
      Throw "One more VMSwitch named $Name remains after destroying WSL network. Please reboot your computer to clean it up."
    }

    # Delete conflicting NetNat
    $wslNetNat = Get-NetNat | Where-Object {$_.InternalIPInterfaceAddressPrefix -Match $AddressPrefix}
    $wslNetNat | Foreach {Remove-NetNat -Confirm:$False -Name:$_.Name}

    # Create new WSL network
    New-HnsNetwork -Name $Name -AddressPrefix $WslSubnet -GatewayAddress $GatewayIP

    # Switch all misconfigured Hyper-V VMs to newly created Virtual VMSwitch 'WSL'
    Write-Host "Switching all misconfigured Hyper-V VMs to newly created VMSwitch $Name ..."
    Get-VM | Get-VMNetworkAdapter | ? SwitchName -eq $null | Connect-VMNetworkAdapter -SwitchName $Name

    # Restart all VMs which failed to start due to network misconfiguration
    # as Virtual switch 'WSL' got deleted at Windows power down
    Get-VM | ? State -Eq Saved | Start-VM

    # Restart all previously started Hyper-V VMs connected to VMSwitch WSL
    if ($wslVMs) {
      Write-Host "Restarting all Hyper-V VMs connected to VMSwitch $Name ..."
      $wslVMs | Foreach { Start-VM -Name $_.VMName }
    }
  }

  # Apply changes to WSL network if or if not using VPN
  $dnsIP,$wslMtu = Set-VpnToggle -Name $Name -reboot $reboot

  # wsl-boot.sh updates primary ip addr to $WslHostIP and starts few services on Linux side.
  wsl $d $distribution -u root /boot/wsl-boot.sh $WslSubnetPrefix $WslHostIP $GatewayIP $dnsIP $wslMtu

  # Kind exit message
  Write-Host "wsl-boot completed !"
}

Start-WslBoot
