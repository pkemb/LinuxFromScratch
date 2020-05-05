#!/tools/bin/bash

ln -sv /tools/bin/{bash,cat,chmod,dd,echo,ln,mkdir,pwd,rm,stty,touch} /bin
ln -sv /tools/bin/{env,install,perl,printf} /usr/bin
ln -sv /tools/lib/libgcc_s.so{,.1}          /usr/lib
ln -sv /tools/lib/libstdc++.{a,so{,.6}}     /usr/lib

ln -sv bash /bin/sh

ln -sv /proc/self/mounts /etc/mtab

if [ ! -f /etc/passwd ]; then
    cat ch6_passwd.txt > /etc/passwd
fi

if [ ! -f /etc/group ]; then
    cat ch6_group.txt > /etc/group
fi

touch /var/log/{btmp,lastlog,faillog,wtmp}
chgrp -v utmp /var/log/lastlog
chmod -v 664 /var/log/lastlog
chmod -v 600 /var/log/btmp
