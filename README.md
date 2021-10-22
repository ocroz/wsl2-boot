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

## DNS aliases

The DNS server on every WSL2 and VM is the static IP of the host, so dynamically it should resolve DNS on every WSL2 and VM like in the host, always.<br/>
However this is not true, so the boot script will take the DNS server provided by the VPN if connected.

## SSH keys

All SSH keys loaded into Windows Pageant can be made accessible to other local systems too:
- Several Windows apps like: PuTTY, FileZilla, TurtoiseGit, etc.
- Git for Windows aka GitBash (which embeds ssh-pageant)
- Cygwin: https://github.com/cuviper/ssh-pageant
- WSL1: https://github.com/vuori/weasel-pageant
- WSL2: https://github.com/BlackReloaded/wsl2-ssh-pageant<br/>
Note: See also https://github.com/BlackReloaded/wsl2-ssh-pageant/issues/23#issuecomment-882068132.

## Localhost forwarding

With `localhostForwarding=true` in `.wslconfig`:<br/> Any app running on Linux at
http://localhost:$port (or https) is accessible at same URL on Windows too.<br/>
Note: Localhost forwarding may fail for privileged ports.

## Sharing files between Windows and Linux

| Access..                 | Windows side         |Linux side|Default line endings of text files|
|--------------------------|----------------------|----------|----------------------------------|
|..Windows files from Linux|`C:\`                 |/mnt/c/   |CRLF                              |
|..Linux files from Windows|`\\wsl$\Ubuntu-20.04\`|/         |LF                                |

**Ownership and Permissions on Windows files**

Some Linux programs like `ansible` don't work if the files are opened to everyone.

On Linux side:
- The Windows files are considered owned by the default WSL2 user i.e. `ubuntu`.
- The Windows files are seen with worldwide permissions +default `umask` and `fmask`.

> Default umask 22 removes w bit for group and everyone on all directories and files.<br/>
> Default fmask 11 removes x bit for group and everyone on files too.

See above `wsl.conf` where to configure default user, umask, fmask.

**Symlinks**

On Linux side, you can create symlinks on Windows files too, like if they are pure Linux files.<br/>
Note: Windows sees this folder/file but cannot open it.

**Default line endings and file mode on your git files**

Some Linux programs don't manage Windows line endings well, whereas Windows seems to manage Linux line endings better.
It may seem wise to configure Linux line endings to all your git repos on both Linux and Windows sides.
With git, Windows defaults the file mode to 644, and Linux defaults the file mode to 755. This difference can be removed too.

<pre>
# On Windows side                               # On Linux side
git config --global core.autocrlf input         sudo git config --system core.autocrlf input
git config --global core.eol lf                 sudo git config --system core.eol lf
git config --global core.fileMode false         sudo git config --system core.fileMode false

# Update all files in working directories with new line endings
cd $gitrepo
git rm --cached -r . ; git reset --hard
</pre>

# Time to play

Install [docker](https://docs.docker.com/engine/install/ubuntu/), [podman](https://podman.io/blogs/2021/06/16/install-podman-on-ubuntu.html), [k3d](https://github.com/rancher/k3d#get) ([blog](https://en.sokube.ch/post/k3s-k3d-k8s-a-new-perfect-match-for-dev-and-test-1)), or anything else.

# References

- https://docs.microsoft.com/en-us/windows/wsl/about
- https://github.com/microsoft/WSL
- https://github.com/sirredbeard/Awesome-WSL
