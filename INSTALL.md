# Installation instructions for wsl2-boot

Please carefully read and understand the scripts before installing them:
- May be you prefer different WSL2 configuration,
- Note: The configuration `generateResolvConf = true` is intended to create /etc/resolv.conf,
- May be you don't want to start ssh and cron services at boot,
- May be you don't want to run the crontab of user root and its @reboot commands,
- May be you don't have Git for Windows installed, so you don't have GitBash,
- May be you don't have Windows pageant installed,
- May be you don't need a ssh agent, or you prefer another solution than Windows pageant,
- May be you have ssh-pageant already configured in GitBash,
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
cat linux/crontab.root | sudo crontab
 
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

- Create a Windows shortcut from your `wsl-boot.bat`,
- Right-click on this shortcut > Select `Properties`,<br/>
  Select tab `Shortcut` > Click on `Advanced...` > Tick `Run as administrator` > `OK` > `OK`,
- Move this Windows shortcut into `%USERPROFILE%\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup`.
