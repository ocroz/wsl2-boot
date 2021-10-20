<#
.SYNOPSIS
  Detect VPN Connection State.
.DESCRIPTION
.NOTES
.LINK
  https://www.harrycaskey.com/detect-vpn-connection-with-powershell/
#>

# Written By: Harry Caskey (harrycaskey@gmail.com)
# In this example, I used "AnyConnect", "Juniper" or "VPN" as the connection name's, but you can change this to whatever fits your environment.
$vpnCheck = Get-WmiObject -Query "Select Name,NetEnabled from Win32_NetworkAdapter where (Name like '%AnyConnect%' or Name like '%Juniper%' or Name like '%VPN%') and NetEnabled='True'"

# Set this value to Boolean if it returns a value it's true, if it does not return a value it's false.
$vpnCheck = [bool]$vpnCheck

# Check if $vpnCheck is true or false.
if ($vpnCheck) {
    return $vpnCheck
    exit(0)
}
else {
    return $vpnCheck
    exit(1)
}
