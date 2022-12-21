@echo off

REM Adjust log path
REM wsl-boot.bat should be in your PATH
REM PS: Using a simple redirection (>%log%) fails to log everything before running wsl-boot.sh in wsl-boot.ps1 so why use tee.

set log=%USERPROFILE%\wsl-boot.log
echo Redirecting everything to %log% too ...
PowerShell -Command "& { wsl-boot.bat 2>&1 | tee %log% }"

REM Exit to force close (as it is run from a Windows scheduled task)
exit
