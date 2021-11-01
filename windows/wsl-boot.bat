@echo off

REM Boot default and other WSL distributions
PowerShell -Command %USERPROFILE%\git\github.com\wsl2-boot\windows\wsl-boot.ps1 -WslSubnetPrefix "192.168.130"
REM PowerShell -Command %USERPROFILE%\git\github.com\wsl2-boot\windows\wsl-boot.ps1 -WslSubnetPrefix "192.168.130" --distribution "Ubuntu-20.04" --ip "192.168.130.2"

REM pause
