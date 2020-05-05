#!/bin/bash

cat > /boot/grub/grub.cfg << "EOF"
# Begin /boot/grub/grub.cfg
set default=0
set timeout=5
insmod ext2
set root=(hd0,2)
menuentry "GNU/Linux, Linux 5.5.3-lfs-9.1" {
    linux     /boot/vmlinuz-5.5.3-lfs-9.1 root=/dev/sda2 ro
}
EOF
