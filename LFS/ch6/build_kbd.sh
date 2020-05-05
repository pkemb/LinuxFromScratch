#!/bin/bash

FILE_NAME=$(basename $0 | sed "s/\.sh//g")
OSS_NAME=kbd
OSS_VER=2.2.0
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
    patch -Np1 -i ../kbd-2.2.0-backspace-1.patch
    sed -i 's/\(RESIZECONS_PROGS=\)yes/\lno/g' configure
    sed -i 's/resizecons.8 //' docs/man/man8/Makefile.in
}

patch_file > ${LOG_DIR}/${FILE_NAME}-patch.log 2>&1

echo "start configure"
PKG_CONFIG_PATH=/tools/lib/pkgconfig \
./configure  \
    --prefix=/usr \
    --disable-vlock \
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
make check -j8 \
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
    mkdir -v /usr/share/doc/kbd-2.2.0
    cp -R -v docs/doc/* /usr/share/doc/kbd-2.2.0
}

install_file 2>&1 | tee -a ${LOG_DIR}/${FILE_NAME}-install.log

