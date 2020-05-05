#!/bin/bash

FILE_NAME=$(basename $0 | sed "s/\.sh//g")
OSS_NAME=binutils
OSS_VER=2.34
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

test_result=$(expect -c "spawn ls")
if [ "$test_result" != "spawn ls" ]; then
    echo "not set up for proper PTY"
    echo "please running the test suites for Binutils and GCC"
    exit 1
fi

function patch()
{
    echo "start patch"
    sed -i '/@\tincremental_copy/d' gold/testsuite/Makefile.in
}

patch  > ${LOG_DIR}/${FILE_NAME}-patch.log 2>&1

mkdir -v build
cd build

echo "start configure"
../configure            \
    --prefix=/usr       \
    --enable-gold       \
    --enable-ld=default \
    --enable-plugins    \
    --enable-shared     \
    --disable-werror    \
    --enable-64-bit-bfd \
    --with-system-zlib  \
    > ${LOG_DIR}/${FILE_NAME}-configure.log 2>&1
if [ $? -ne 0 ]; then
    echo "configure error, please check ${LOG_DIR}/${FILE_NAME}-configure.log"
    exit 1
fi

echo "start make"
make -j8 tooldir=/usr \
    > ${LOG_DIR}/${FILE_NAME}-make.log 2>&1
if [ $? -ne 0 ]; then
    echo "make error, please check ${LOG_DIR}/${FILE_NAME}-make.log"
    exit 1
fi

echo "start make check"
make -k check -j8 \
    > ${LOG_DIR}/${FILE_NAME}-make-check.log 2>&1
if [ $? -ne 0 ]; then
    echo "make check error, please check ${LOG_DIR}/${FILE_NAME}-make-check.log"
    exit 1
fi

echo "start make install"
make tooldir=/usr install \
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

