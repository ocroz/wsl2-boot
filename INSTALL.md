# Installation instructions for wsl2-boot

Please carefully read and understand the scripts before installing them:
- May be you prefer different WSL2 configuration,
- Note: The configuration `generateResolvConf = false` works only if<br/>
  `/etc/resolv.conf` is not a symlink, exists already or is managed by `wsl-boot.bat`,
- May be you don't want to start ssh service at boot,

```bash
# From the WSL2 machine, say ubuntu, in a path accessible from Windows
windowsUsername=crozier # this your username on Windows
mkdir -p /mnt/c/Users/${windowsUsername}/git/github.com
cd $_
git clone https://github.com/ocroz/wsl2-boot
cd wsl2-boot

# Create environment variable on Windows
Windows > Settings > System > About > Advanced System Settings > Environment Variables
(user variables) New... > Name = WSL2_BOOT, Value = %USERPROFILE%\git\github.com\wsl2-boot (where you cloned) > OK

# First time on Linux
sudo visudo
< %sudo   ALL=(ALL:ALL) ALL
> %sudo   ALL=(ALL:ALL) NOPASSWD: ALL
sudo apt update
sudo apt upgrade -y
sudo apt install -y dos2unix
sudo ssh-keygen -A

# How to create /etc/resolv.conf
# 1. Static solution
#    - `rm /etc/resolv.conf`        # Remove the symlink
#    - `vi /etc/resolv.conf`        # Create file as per your needs
#    - `chattr +i /etc/resolv.conf` # Make it unmodifiable
# 2. Dynamic solution (allows to adapt DnsServer and DnsSearch on the fly when you connect/disconnect VPN)
#    Pass DnsServer to /boot/wsl-boot.sh with option -n (see wsl-boot.bat), then:
#    - either `generateResolvConf = true` in `/etc/wsl.conf`, # So WSL creates /run/resolvconf/resolv.conf at boot
#    - or `generateResolvConf = false` and `rm /etc/resolv.conf` # Remove link to unexistent file

# Linux part
sudo rm /etc/resolv.conf # see above dynamic solution
sudo cp linux/wsl.conf /etc/
sudo cp linux/wsl-boot.sh /boot/
sudo chmod 744 /boot/wsl-boot.sh
sudo dos2unix /etc/wsl.conf /boot/wsl-boot.sh
#cat linux/crontab.root | sudo crontab
 
# Windows part
cat windows/.bash_profile >>/mnt/c/Users/${windowsUsername}/.bash_profile
cp windows/.wslconfig /mnt/c/Users/${windowsUsername}/
cp windows/wsl-boot.bat /mnt/c/Users/${windowsUsername}/winbin/ # Or wherever in your Windows PATH

# Update wsl-boot.bat as per your need
# - Update the path to `wsl-boot.ps1` as per your settings
# - Update the subnet as you need e.g. to replace "192.168.50" by "192.168.130"
# - Add all your WSL distributions
# - Replace `PowerShell` by `pwsh` if to use PowerShell 7.1+
vi /mnt/c/Users/${windowsUsername}/winbin/wsl-boot.bat
 
# Don't forget to load your SSH private key into Windows pageant, and to add the SSH public key into Linux
mkdir -p ~/.ssh; vi ~/.ssh/authorized_keys; chmod 700 ~/.ssh; chmod 600 ~/.ssh/*
```

## Start `wsl-boot` at Windows startup

There is no other way than to create a Windows scheduled task like [jgregmac](https://github.com/jgregmac) did with [hyperv-fix-for-devs](https://github.com/jgregmac/hyperv-fix-for-devs)<br/>
if to run [wsl-boot-task.bat](./windows/wsl-boot-task.bat) with elevated permissions (Run As Administrator).
- Open the [Windows Task Scheduler](https://www.windowscentral.com/how-create-automated-task-using-task-scheduler-windows-10),
- Select `Task Scheduler Library` from the left panel, and Right-click on it,
- Select `Create Task...`,
- Tab General: Name = `wsl-boot`, tick `Run with highest privileges`, tick `hidden` +configure for `Windows 10`,
- Tab Triggers: New... > Begin the task `At log on` specific user,
- Tab Triggers: New... > Begin the task `On event`:<br/>
  Log: Microsoft-Windows-NetworkProfile/Operational<br/>
  Source: NetworkProfile<br/>
  Event ID: 10000 (The 10000 Event ID is logged when you connect to a network),
- Tab Triggers: New... > Begin the task `On event`:<br/>
  Log: Microsoft-Windows-NetworkProfile/Operational<br/>
  Source: NetworkProfile<br/>
  Event ID: 10001 (The 10001 Event ID is logged when you disconnect from a network),
- Tab Actions: New... ><br/>
  Program = `C:\WINDOWS\system32\cmd.exe`,<br/>
  Arguments = `/c start /min %WSL2_BOOT%\windows\wsl-boot-task.bat`,
- Tab Conditions: Keep default,
- OK

Notes:
- We trigger when VPN connected or disconnected too, see:<br/>
  https://www.groovypost.com/howto/automatically-run-script-on-internet-connect-network-connection-drop/
- We run `wsl-boot-task.bat` to log and force exit.
