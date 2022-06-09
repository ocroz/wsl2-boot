# Boot WSL2 machine with static IP

This project brings solutions to several WSL2 issues like:
- [WSL2 Set static ip?](https://github.com/microsoft/WSL/issues/4210)
- [WSL IP address & Subnet is never deterministic (Constantly changing)](https://github.com/microsoft/WSL/issues/4467)

Other projects exist to solve them, among others:
- https://github.com/skorhone/wsl2-custom-network
- https://github.com/jgregmac/hyperv-fix-for-devs
- https://github.com/wikiped/WSL-IpHandler

## Advantages of wsl2-boot

After running `wsl-boot` command:
- The WSL network is configured as per its predefined definition always (Windows side),
- All WSL hosts are configured with their predefined static IP always (Linux side),
- All WSL hosts and connected Hyper-V VMs can talk to each other always,
- The DNS resolution works however you are connected to Internet or VPN,
- You can SSH to WSL host without any delay.

Other advantages:
- This project is short and simple,
- It uses native PowerShell functions apart `New-HnsNetwork()`, and the native `wsl` command,
- The unique command `wsl-boot` starts everything cleanly and completely, including the connected VMs,
- You can boot either from a PowerShell or cmd prompt, or double click on bat file, or at Windows startup,
- This script was tested with PowerShell 5.1 and 7.1.

# Installation

See detailed [INSTALL](./INSTALL.md) instructions.

## Goals

**Network requirements**

- The host, every WSL2 machine, and every VM has a static IP always.
- The host can see and connect to every WSL2 and VM, and vice versa, always.
- Every WSL2 and VM can see and connect to every other WSL2 and VM always.
- Every WSL2 and VM has Internet connection through the host, no matter how the host is connected\*, always.<br/>
  \*Cable, Wifi, Mobile endpoint, VPN.

**Two but One machine**

Everything that Windows accesses and knows is accessible and known to WSL too:
- Local and remote IPs
- DNS aliases
- SSH keys

Every application that WSL serves is accessible at localhost on Windows too:
- Note: Privileged ports like 80 and 443 are not forwarded by default.

## WSL2 configuration

More details at https://docs.microsoft.com/en-us/windows/wsl/wsl-config#wsl-2-settings
- Windows: [.wslconfig](./windows/.wslconfig)
- Linux: [wsl.conf](./linux/wsl.conf)

## The boot flow

The command `wsl-boot` starts this flow:
1. [wsl-boot](./windows/wsl-boot.bat) (.bat) (**Run As Administrator**) ->
2. [wsl-boot.ps1](./windows/wsl-boot.ps1) (PowerShell): `clean shutdown` + [New-HnsNetwork()](./windows/HnsEx.ps1) + `clean start` ->
3. [/boot/wsl-boot.sh](./linux/wsl-boot.sh) (bash as root): set static ip, start service ssh, then returns immediately.

*Addendum:*<br/>
The order in `clean shutdown` and `clean start` is necessary for everything to work, especially the communication between all WSL hosts and other Hyper-V VMs, the Internet connection and the DNS resolution, and the first SSH to WSL.
See also Addendum in [TODO](./doc/TODO.md).

# Few considerations

## Other VMs

The WSL2 machine and all other VMs must be connected to the same virtual switch named `WSL`, and have static IP in the same subnet, like:
- Windows host: 192.168.50.1
- WSL2 machine: 192.168.50.2
- Other VM one: 192.168.50.100

## DNS aliases

The DNS server on every WSL2 and VM is the static IP of the host, so dynamically it should resolve DNS on every WSL2 and VM like in the host, always (at least if running a `clean shutdown` and `clean start`).

However, the DNS fails to work properly in containers (docker, podman) inside the WSL host. The only solution if to reach remote DNS resources is to patch the DNS nameserver with the one provided by the VPN, which can be achieved if running `wsl-boot` everytime the VPN connected or disconnected (See [INSTALL](./INSTALL.md)).

*Addendum:*<br/>
The original implementation of this project [wsl2-boot](https://github.com/ocroz/wsl2-boot) derived from [WSL/issues/4210#issuecomment-856482892](https://github.com/microsoft/WSL/issues/4210#issuecomment-856482892).
However the DNS resolution failed to work if the Windows host was connected via a VPN. Creating a **H**ost **C**ompute **N**etwork (HCN) solved this problem. A big thanks to [skorhone](https://github.com/skorhone) and the solution [wsl2-custom-network](https://github.com/skorhone/wsl2-custom-network).

## HCN architecture

See: https://docs.microsoft.com/en-us/virtualization/windowscontainers/container-networking/architecture

## Troubleshoot

```powershell
# Force re-creating the WSL network with this command,
# which you run from an elevated prompt (Run As Administrator)
wsl-boot -force
wsl-boot -force -Debug
```

## Use WSL2 daily

See [DAILY](./doc/DAILY.md).
