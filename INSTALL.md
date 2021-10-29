# Installation instructions for wsl2-boot

Warning: This is an opinioniated solution to boot the WSL2 machine.<br/>
For now, it supports one WSL2 machine only, the default one.

Please carefully read and understand the scripts before installing them:
- May be you prefer different WSL2 configuration,
- Note: The configuration `generateResolvConf = true` is intended to create /etc/resolv.conf,
- May be you prefer to set the DNS nameserver on WSL2 to always the same fixed IP,
- May be you prefer to keep all existing NAT networks, although Windows does not support multiple NAT networks,
- May be you don't want to start ssh and cron services at boot,
- May be you don't want to run the crontab of user root and its @reboot commands,
- May be you don't have Git for Windows installed, so you don't have GitBash,
- May be you don't have Windows pageant installed,
- May be you don't need a ssh agent, or you prefer another solution than Windows pageant,
- May be you have ssh-pageant already configured in GitBash,
- Please set variable windowsUsername before copy files on Windows.

```bash
# From the WSL2 machine, say ubuntu
git clone https://github.com/ocroz/wsl2-boot
cd wsl2-boot
 
# Update the subnet as you need e.g. to replace "192.168.50" by "192.168.130"
find [lw]*/ -type f -exec sed -i 's,\.50,.130,g' {} \;
git diff
 
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
cp windows/*.ps1 /mnt/c/Users/${windowsUsername}/winbin/ # Or wherever in your Windows PATH
 
# Don't forget to load your SSH private key into Windows pageant, and to add the SSH public key into Linux
mkdir -p ~/.ssh; vi ~/.ssh/authorized_keys; chmod 700 ~/.ssh; chmod 600 ~/.ssh/*
```
