@echo off

REM Adjust log path
REM wsl-boot.bat should be in your PATH
REM Git for Windows should be installed at "C:\Program Files\Git"
REM PS: Using a simple redirection (>%log%) fails to log everything before running wsl-boot.sh in wsl-boot.ps1 so why use tee.

Set log=%USERPROFILE%\wsl-boot.log
Echo Redirecting everything to %log% too ...
cmd /c wsl-boot.bat 2>&1 | "%ProgramFiles%\Git\usr\bin\tee" %log%

REM Exit to force close (as it is run from a Windows scheduled task)
exit
