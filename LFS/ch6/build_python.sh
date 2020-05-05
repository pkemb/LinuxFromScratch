#!/bin/bash

FILE_NAME=$(basename $0 | sed "s/\.sh//g")
OSS_NAME=Python
OSS_VER=3.8.1
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

echo "start configure"
./configure  \
    --prefix=/usr \
    --enable-shared \
    --with-system-expat \
    --with-system-ffi \
    --with-ensurepip-yes \
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
    chmod -v 755 /usr/lib/libpython3.8.so
    chmod -v 755 /usr/lib/libpython3.so
    ln -sfv pip3.8 /usr/bin/pip3
}

install_file 2>&1 | tee -a ${LOG_DIR}/${FILE_NAME}-install.log

