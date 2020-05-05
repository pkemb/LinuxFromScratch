#!/bin/bash

FILE_NAME=$(basename $0 | sed "s/\.sh//g")
OSS_NAME=coreutils
OSS_VER=8.31
OSS=$(ls ${OSS_NAME}-${OSS_VER}.tar*)

LOG_DIR=/log/ch6
mkdir -p ${LOG_DIR}
rm ${LOG_DIR}/${FILE_NAME}*

echo "delete ${OSS_NAME}-${OSS_VER}"
rm -rf ${OSS_NAME}-${OSS_VER}

$(dirname $0)/extract_package.sh $OSS ${LOG_DIR}/${FILE_NAME}-$(basename $OSS).log
if [ $? -ne 0 ]; then
    exit 1
fi

echo "enter ${OSS_NAME}-${OSS_VER}"
cd ${OSS_NAME}-${OSS_VER}
if [ $? -ne 0 ]; then
    echo "enter fail, please check"
    exit 1
fi

#######################################
# compile instructions that from book
#######################################

function patch_file()
{
    echo "start patch"
    patch -Np1 -i ../coreutils-8.31-i18n-1.patch
    sed -i '/test.lock/s/^/#/' gnulib-tests/gnulib.mk
}

patch_file > ${LOG_DIR}/${FILE_NAME}-patch.log 2>&1

echo "start configure"
autoreconf -fiv
FORCE_UNSAFE_CONFIGURE=1 \
./configure  \
    --prefix=/usr \
    --enable-no-install-program=kill,uptime \
    > ${LOG_DIR}/${FILE_NAME}-configure.log 2>&1
if [ $? -ne 0 ]; then
    echo "configure error, please check ${LOG_DIR}/${FILE_NAME}-configure.log"
    exit 1
fi

echo "start make"
make -j8 \
    > ${LOG_DIR}/${FILE_NAME}-make.log 2>&1
if [ $? -ne 0 ]; then
    echo "make error, please check ${LOG_DIR}/${FILE_NAME}-make.log"
    exit 1
fi

function coreutils_check()
{
     echo "start make check"
     make NON_ROOT_USERNAME=nobody check-root || return 1
     echo "dummy:x:1000:nobody" >> /etc/group
     chown -Rv nobody .
     su nobody -s /bin/bash \
               -c "PATH=$PATH make RUN_EXPENSIVE_TESTS=yes check"
     if [ $? -ne 0 ]; then
          echo "make check error"
     fi
     sed -i '/dummy/d' /etc/group
}

coreutils_check \
    > ${LOG_DIR}/${FILE_NAME}-make-check.log 2>&1
if [ $? -ne 0 ]; then
    echo "make check error, please check ${LOG_DIR}/${FILE_NAME}-make-check.log"
    exit 1
fi

echo "start make install"
make install \
    > ${LOG_DIR}/${FILE_NAME}-make-install.log 2>&1
if [ $? -ne 0 ]; then
    echo "make install error, please check ${LOG_DIR}/${FILE_NAME}-make-install.log"
    exit 1
fi

function install_file()
{
    echo "start manual install file"
    mv -v /usr/bin/{cat,chgrp,chmod,chown,cp,date,dd,df,echo} /bin
    mv -v /usr/bin/{false,ln,ls,mkdir,mknod,mv,pwd,rm} /bin
    mv -v /usr/bin/{rmdir,stty,sync,true,uname} /bin
    mv -v /usr/bin/chroot /usr/sbin
    mv -v /usr/share/man/man1/chroot.1 /usr/share/man/man8/chroot.8
    sed -i s/\"1\"/\"8\"/1 /usr/share/man/man8/chroot.8
    mv -v /usr/bin/{head,nice,sleep,touch} /bin
}

install_file 2>&1 | tee -a ${LOG_DIR}/${FILE_NAME}-install.log

