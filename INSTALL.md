# Installation instructions for wsl2-boot

Please carefully read and understand the scripts before installing them:
- May be you prefer different WSL2 configuration,
- Note: The configuration `generateResolvConf = true` is intended to create /etc/resolv.conf,
- May be you don't want to start ssh service at boot,
- May be you don't have Git for Windows installed, so you don't have GitBash and tee,
- Please set variable windowsUsername before run these commands.

```bash
# From the WSL2 machine, say ubuntu, in a path accessible from Windows
mkdir -p /mnt/c/Users/${windowsUsername}/git/github.com
cd $_
git clone https://github.com/ocroz/wsl2-boot
cd wsl2-boot

# First time on Linux
sudo visudo
< %sudo   ALL=(ALL:ALL) ALL
> %sudo   ALL=(ALL:ALL) NOPASSWD: ALL
sudo apt update
sudo apt upgrade -y
sudo apt install -y dos2unix
sudo ssh-keygen -A
 
# Linux part
sudo cp linux/wsl.conf /etc/
sudo cp linux/wsl-boot.sh /boot/
sudo chmod 744 /boot/wsl-boot.sh
#cat linux/crontab.root | sudo crontab
 
# Windows part
unix2dos windows/.[bw]* windows/*
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
- Tab General: Name = `wsl-boot`, tick `Run with highest privileges`,
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
  Arguments = `/c start /min %USERPROFILE%\git\github.com\wsl2-boot\windows\wsl-boot-task.bat`,
- Tab Conditions: Keep default,
- OK

Notes:
- We trigger when VPN connected or disconnected too, see:<br/>
  https://www.groovypost.com/howto/automatically-run-script-on-internet-connect-network-connection-drop/
- We run `wsl-boot-task.bat` to log and force exit.
