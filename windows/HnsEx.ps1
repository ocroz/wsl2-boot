# Add missing PowerShell function New-HnsNetwork()
# related to existing Get-HnsNetwork() and Remove-HnsNetwork() functions

function New-HnsNetwork() {
  Param(
    [parameter(Mandatory=$true)] [String] $Name = "WSL",
    [parameter(Mandatory=$true)] [String] $AddressPrefix = "192.168.50.0/24"
    [parameter(Mandatory=$true)] [String] $GatewayAddress = "192.168.50.1"
  )

  # Helper functions first
  function Get-HcnMethods() {
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
  $network = [ordered]@{
    Name = $Name
    Type = "ICS"
    IPv6 = $false
    IsolateSwitch = $true
    MaxConcurrentEndpoints = 1
    Subnets =  @([ordered]@{
      AddressPrefix = $AddressPrefix
      GatewayAddress = $GatewayAddress
      IpSubnets = @(@{ IpAddressPrefix = $AddressPrefix })
    })
    DNSServerList = $GatewayAddress
  }
  $settings = $network | ConvertTo-Json -Depth 100

  $hcnClientApi = Get-HcnMethods
  $id = "A1B2C3D4-E5F6-1234-4321-F6E5D4C3B2A1"
  $handle = 0
  $result = ""
  $hr = $hcnClientApi::HcnCreateNetwork($id, $settings, [ref] $handle, [ref] $result)
  Write-HcnErr -FunctionName HcnCreateNetwork -Hr $hr -Result $result

  # Function 'echo' fails if calling ps1 from another ps1
  Write-Host "Network created with these parameters: $settings"
}
