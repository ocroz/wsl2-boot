<#
.SYNOPSIS
  Apply changes to WSL network if or if not using VPN.
.DESCRIPTION
  Unfortunately, WSL2 works degraded under VPN, unless doing few changes.
  See few issues among others in link.
.NOTES
.LINK
  - https://www.harrycaskey.com/detect-vpn-connection-with-powershell/
  - https://github.com/microsoft/WSL/issues/4246
  - https://github.com/microsoft/WSL/issues/4277
  - https://gist.github.com/pyther/b7c03579a5ea55fe431561b502ec1ba8
  - https://github.com/microsoft/WSL/issues/6264
#>

function Set-VpnToggle() {
  Param(
    [parameter(Mandatory=$false)] [String] $Name = "WSL",
    [parameter(Mandatory=$false)] [String] $distribution = $null,
    [parameter(Mandatory=$false)] [Bool] $reboot = $False
  )
  if ($distribution) { $d = "-d" }
  Write-Debug "Set-VpnToggle() with Name=$Name, reboot=$reboot ..."

  # There must be only one VMSwitch for WSL always
  if ((Get-VMSwitch -Name $Name -ea "SilentlyContinue").Count -gt 1) {
    Throw "More than one VMSwitch named $Name exist. Please reboot your computer to clean them all."
  }

  # Get connected VPN
  $vpnStrings = @("Cisco AnyConnect", "Juniper", "VPN")
  $vpnNet = Get-NetAdapter | ? status -eq Up | Where {
    $found=$False
    Foreach($str in $vpnStrings) {
      if ($_.InterfaceDescription.contains($str)) {$found=$True;break}
    }
    $found
  }

  # > To adjust Mtu to VPN capability
  $phyMtu = Get-NetAdapter -Physical | ? status -eq Up | Get-NetIPInterface -AddressFamily IPv4 | Select-Object -ExpandProperty NlMtu
  $wslMtu = Get-NetIPInterface -InterfaceAlias "vEthernet ($Name)" -AddressFamily IPv4 | Get-NetIPInterface -AddressFamily IPv4 | Select-Object -ExpandProperty NlMtu
  Write-Debug "phyMtu=$phyMtu,wslMtu=$wslMtu"

  # > To patch DNS nameserver under VPN
  $dnsIP = "" # Let Windows determine default dnsIP
  if ($reboot) { Write-Debug "wsl --shutdown"; wsl --shutdown } # Take default dnsIP if not using VPN
  wsl $d $distribution --list --running >$null; if ($?) { $dnsIP = $GatewayIP } # Force dnsIP = GatewayIP if VPN disconnected
  Write-Debug "dnsIP=$dnsIP"

  # Different actions if or if not under VPN
  if ($vpnNet) {
    # Apply changes if using VPN

    # If WSL2 lost connectivity under VPN (not the case for me)
    # $vpnNet | Set-NetIPInterface -InterfaceMetric 6000

    # Adjust Mtu to VPN capability
    $vpnMtu = $vpnNet | Get-NetIPInterface -AddressFamily IPv4 | Select-Object -ExpandProperty NlMtu
    if ($vpnMtu -lt $phyMtu -and $wslMtu -ne $vpnMtu) {
      Write-Host "Patching NetIPInterface ""vEthernet ($Name)"" with NlMtu=$vpnMtu ..."
      Get-NetIPInterface -InterfaceAlias "vEthernet ($Name)" | Set-NetIPInterface -NlMtu $vpnMtu
      $wslMtu = $vpnMtu
    }

    # Patch DNS nameserver under VPN
    $dnsIPs = $vpnNet | Get-DnsClientServerAddress -AddressFamily IPv4 | Select-Object -ExpandProperty ServerAddresses
    $dnsIP=$dnsIPs[0]
  } else {
    # Revert any change if not using VPN

    # Set defaults when there is no Internet connection
    if ($phyMtu -eq $null) {
      $phyMtu = Get-NetAdapter -Physical | Get-NetIPInterface -AddressFamily IPv4 | Select-Object -ExpandProperty NlMtu
      $phyMtu = $phyMtu[0]
    }

    if ($wslMtu -ne $phyMtu)  {
      Write-Host "Patching NetIPInterface ""vEthernet ($Name)"" with NlMtu=$phyMtu ..."
      Get-NetIPInterface -InterfaceAlias "vEthernet ($Name)" | Set-NetIPInterface -NlMtu $phyMtu
      $wslMtu = $phyMtu
    }

    # No need to patch MTU on Linux side if WSL has been shutdown
    if (-not $dnsIP) { $wslMtu = "" }
  }

  # Return settings to apply on Linux side too
  Write-Debug "dnsIP=$dnsIP,wslMtu=$wslMtu."
  return $dnsIP,$wslMtu
}
