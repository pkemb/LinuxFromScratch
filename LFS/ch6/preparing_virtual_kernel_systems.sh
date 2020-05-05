#!/bin/bash

LFS=/mnt/lfs

mkdir -pv $LFS/{dev,proc,sys,run}

# creating initial decice notes
if [ ! -c $LFS/dev/console ]; then
    mknod -m 600 $LFS/dev/console c 5 1
fi

if [ ! -c $LFS/dev/null ]; then
    mknod -m 666 $LFS/dev/null c 1 3
fi

# mounting and population dev
mount -v --bind /dev $LFS/dev

mount -vt devpts devpts $LFS/dev/pts -o gid=5,mode=620
mount -vt proc proc $LFS/proc
mount -vt sysfs sysfs $LFS/sys
mount -vt tmpfs tmpfs $LFS/run

if [ -h $LFS/dev/shm ]; then
    mkdir -pv $LFS/$(readlink $LFS/dev/shm)
fi
