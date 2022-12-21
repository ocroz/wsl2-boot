# Remaining To Do

The most important is: This solution works !

Now, I am not an expert in PowerShell. The code could be written in a cleaner way.

Any contribution is welcome.

The main point of focus for me is: it should remain short and simple to keep it readable and understandable.

Among others:
- Automate the Windows task creation?
- How best to log?
- What if Git for Windows is not installed, or in a different directory than "C:\Program Files\Git"?
  > Alternatively: Use the native PowerShell scriptlet tee.
- Can we pass parameter `-debug` rather than `-debug True` (same about -force) ?
  > Yes we can, by using type 'Switch' rather than 'Bool'.
- How to Write-Debug in main script?
- How best to pass the debug parameter to children scripts and functions?
- Error handling?

# Addendum

In the original solution, `wsl-boot.sh` started the service cron too, so the boot flow continued with these other steps.

4. [crontab.root](./linux/wsl-boot.sh) (cron as root): This runs the crontab of user root and its @reboot commands.
5. (cron as root > GitBash as current Windows user):<br/>
`bash.exe --login` sources [.bash_profile](./windows/.bash_profile) and proxies Windows Pageant to get its SSH keys<br/>
in order to succeed `ssh ubuntu@IP whoami`.<br/>
Note: In the original solution, with updating fixed IP at boot, ssh took approx 16s to complete the very first time.<br/>
At least with this trick, it was automated, so as a user we shouldn't have to wait that much anymore.
