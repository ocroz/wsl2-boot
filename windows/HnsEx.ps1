<#
.SYNOPSIS
  Add missing PowerShell function New-HnsNetwork()
  related to existing Get-HnsNetwork() and Remove-HnsNetwork() functions.
.DESCRIPTION
  This script provides a new function New-HnsNetwork()
  derived from the function New-HnsNetworkEx() provided by the referenced script
  and simplified at a maximum.
.NOTES
.LINK
  https://www.powershellgallery.com/packages/HNS/0.2.4/Content/HNS.V2.psm1
#>

function New-HnsNetwork() {
  Param(
    [parameter(Mandatory=$true)] [String] $Name = "WSL",
    [parameter(Mandatory=$true)] [String] $AddressPrefix = "192.168.50.0/24",
    [parameter(Mandatory=$true)] [String] $GatewayAddress = "192.168.50.1"
  )
  if ($PSBoundParameters['Debug']) { $DebugPreference = "Continue" }
  Write-Debug "Creating new network with Name $Name, AddressPrefix $AddressPrefix, GatewayAddress $GatewayAddress ..."

  # Helper functions first
  function Get-HcnMethods() {
    $DebugPreference = "SilentlyContinue"
    $signature = @'
      [DllImport("computenetwork.dll")] public static extern System.Int64 HcnCreateNetwork(
        [MarshalAs(UnmanagedType.LPStruct)] Guid Id,
        [MarshalAs(UnmanagedType.LPWStr)]   string Settings,
        [MarshalAs(UnmanagedType.SysUInt)]  out IntPtr Network,
        [MarshalAs(UnmanagedType.LPWStr)]   out string Result
      );
'@
    Add-Type -MemberDefinition $signature -Namespace ComputeNetwork.HNS.PrivatePInvoke -Name NativeMethods -PassThru
  }
  function Write-HcnErr {
      $errorOutput = ""
      if($Hr -ne 0) {
        $errorOutput += "HRESULT: $($Hr). "
      }
      if(-NOT [string]::IsNullOrWhiteSpace($Result)) {
        $errorOutput += "Result: $($Result)"
      }
      if(-NOT [string]::IsNullOrWhiteSpace($errorOutput)) {
        $errString = "$($FunctionName) -- $($errorOutput)"
        throw $errString
      }
  }

  # Create this network
  $settings = @"
    {
      "Name" : "WSL",
      "Type": "ICS",
      "IPv6": false,
      "IsolateSwitch": true,
      "MaxConcurrentEndpoints": 1,
      "Subnets" : [
        {
          "AddressPrefix" : "$AddressPrefix",
          "GatewayAddress" : "$GatewayAddress",
          "IpSubnets" : [
            {
              "IpAddressPrefix": "$AddressPrefix"
            }
          ]
        }
      ],
      "DNSServerList" : "$GatewayAddress"
    }
"@
  Write-Debug "Creating network with these parameters: $settings"

  $hcnClientApi = Get-HcnMethods
  $id = "B95D0C5E-57D4-412B-B571-18A81A16E005"
  $handle = 0
  $result = ""
  $hr = $hcnClientApi::HcnCreateNetwork($id, $settings, [ref] $handle, [ref] $result)
  Write-HcnErr -FunctionName HcnCreateNetwork -Hr $hr -Result $result

  # Function 'echo' fails if calling ps1 from another ps1
  Write-Host "Network created with these parameters: $settings"
}
