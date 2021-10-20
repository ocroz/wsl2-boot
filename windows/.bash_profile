################################
# ssh-keys with Windows pageant
################################

# git-for-windows comes with ssh-pageant
eval $(/usr/bin/ssh-pageant -r -a "/tmp/.ssh-pageant-$USERNAME")
