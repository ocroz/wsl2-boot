@echo off

REM Keep these 2 lines
set job=%USERPROFILE%\wsl-boot.job
if exist %job% (echo Cannot run this script several times at a time, exiting ... & goto :eof) else (echo. 2>%job%)

REM Boot default and other WSL distributions
PowerShell -Command %WSL2_BOOT%\windows\wsl-boot.ps1 -WslSubnetPrefix "192.168.130" %*
REM PowerShell -Command %WSL2_BOOT%\windows\wsl-boot.ps1 -WslSubnetPrefix "192.168.130" -distribution "Ubuntu-20.04.01" -ip "192.168.130.2"

REM If to keep on screen (if double click on this bat file)
REM pause

REM Keep these 2 lines
del %job%
:eof
