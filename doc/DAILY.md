# Use WSL2 daily

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
