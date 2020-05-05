#!/bin/bash

FILE_NAME=$(basename $0 | sed "s/\.sh//g")
OSS_NAME=util-linux
OSS_VER=2.35.1
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
}

#patch_file > ${LOG_DIR}/${FILE_NAME}-patch.log 2>&1

mkdir -pv /var/lib/hwclock

echo "start configure"
./configure  \
    ADJTIME_PATH=/var/lib/hwclock/adjtime \
    --docdir=/usr/share/doc/util-linux-2.35.1 \
    --disable-chfn-chsh \
    --disable-login \
    --disable-nologin \
    --disable-su \
    --disable-setpriv \
    --disable-runuser \
    --disable-pylibmount \
    --disable-static \
    --without-python \
    --without-systemd \
    --without-systemdsystemunitdir \
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

echo "start make check"
chown -R nobody .
su nobody -s /bin/bash -c "PATH=$PATH make -k check" \
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
}

#install_file 2>&1 | tee -a ${LOG_DIR}/${FILE_NAME}-install.log

