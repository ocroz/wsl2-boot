# Disclaimer

Reference issue: [WSL2 Set static ip?](https://github.com/microsoft/WSL/issues/4210)

Other projects exists to solve this issue:
- https://github.com/skorhone/wsl2-custom-network
- https://github.com/jgregmac/hyperv-fix-for-devs
- https://github.com/wikiped/WSL-IpHandler

# Boot WSL2 machine with static IP

Windows always assigns the WSL2 machine with a different IP at boot.<br/>
Moreover, Windows supports one NAT network only.<br/>
This makes difficult to connect WSL2 machine to other VMs hosted on Hyper-V or VirtualBox under an internal NAT network.<br/>
In addition to above problem, the DNS resolution may fail if connected via a VPN.

This solution allows to:
- Set a static IP to the WSL2 machine,
- Connect it to other VMs (all having their own static IP in the same internal subnet as WSL2),
- Provide the network access of the host to WSL2 and all other VMs,
- Delete all NAT networks but WSL one,
- Adapt the DNS nameserver on WSL2 depending on how you are connected via VPN or not,
- Start ssh daemon on WSL2 so you can connect from GitBash too.

## Goal: Network requirements

- The host, every WSL2 machine, and every VM has a static IP always.
- The host can see and connect to every WSL2 and VM, and vice versa, always.
- Every WSL2 and VM can see and connect to every other WSL2 and VM always.
- Every WSL2 and VM has Internet connection through the host, no matter how the host is connected\*, always.<br/>
  \*Cable, Wifi, Mobile endpoint, VPN.

## Goal: Two but One machine

Everything that Windows accesses and knows is accessible and known to WSL too:
- Local and remote IPs
- DNS aliases
- SSH keys

Every application that WSL serves is accessible at localhost on Windows too:
- Note: Privileged ports like 80 and 443 are not forwarded by default.

## Installation

See detailed [INSTALL](./INSTALL.md) instructions.

WSL2 configuration:
- https://docs.microsoft.com/en-us/windows/wsl/wsl-config#wsl-2-settings
- Windows: [.wslconfig](./windows/.wslconfig)
- Linux: [wsl.conf](./linux/wsl.conf)

The boot flow:
- Derived from: https://github.com/microsoft/WSL/issues/4210#issuecomment-856482892
- From PowerShell(Run As Administrator), run the command `wsl-boot`, this will start the following boot flow.
- See also the header notes in the `wsl-boot.ps1` script.

1. PowerShell(Run As Administrator): [wsl-boot.ps1](./windows/wsl-boot.ps1) > This calls the 2 next scripts,<br/>
   then checks and possibly updates the IP subnet in the NetAdapter and the NetNat on Windows side.
2. PowerShell(Run As Administrator): [isVpnConnected.ps1](./windows/isVpnConnected.ps1) > An utility to detect VPN connection state.
3. bash(root): [/boot/wsl-boot.sh](./linux/wsl-boot.sh) > This sets static IP, starts services ssh & cron, then returns immediately.
4. cron(root): [crontab.root](./linux/wsl-boot.sh) > This runs the crontab of user root and its @reboot commands.
5. GitBash(Current Windows User): `bash.exe --login` sources [.bash_profile](./windows/.bash_profile) and proxies Windows Pageant to get its SSH keys to succeed `ssh ubuntu@IP whoami`

Note: With updating fixed IP at boot, ssh takes approx 16s to complete the very first time.<br/>
At least now it's automated, so as a user we shouldn't wait that much anymore.

# Few considerations

## Other VMs

The WSL2 machine and all other VMs must be connected to the same virtual switch named `WSL`, and have static IP in the same subnet, like:
- Windows host: 192.168.50.1
- WSL2 machine: 192.168.50.2
- Other VM one: 192.168.50.100

After you recreated the WSL network at Windows reboot, you could assign all VMs to it, like:

```powershell
Get-VM | Get-VMNetworkAdapter | Connect-VMNetworkAdapter -SwitchName WSL
Get-VM | ? State -Eq Saved | Start-VM
```

## DNS aliases

The DNS server on every WSL2 and VM is the static IP of the host, so dynamically it should resolve DNS on every WSL2 and VM like in the host, always.<br/>
However this is not true, so the boot script will take the DNS server provided by the VPN if connected.

Note: Creating a **H**ost **C**ompute **N**etwork (HCN) solves this problem. See the other projects in the disclaimer.

You would need to delete all existing NetNat to make these other solutions to work.

```powershell
Get-NetNat | Remove-NetNat
```

## HCN architecture

See: https://docs.microsoft.com/en-us/virtualization/windowscontainers/container-networking/architecture

## Use WSL2 daily

See [DAILY](./DAILY.md)
