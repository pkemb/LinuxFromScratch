#!/bin/bash

FILE_NAME=$(basename $0 | sed "s/\.sh//g")
OSS_NAME=ncurses
OSS_VER=6.2
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

function patch()
{
    echo "start patch"
    sed -i '/LIBTOOL_INSTALL/d' c++/Makefile.in
}

patch  > ${LOG_DIR}/${FILE_NAME}-patch.log 2>&1

echo "start configure"
./configure  \
    --prefix=/usr \
    --mandir=/usr/share/man \
    --with-shared \
    --without-debug \
    --without-normal \
    --enable-pc-files \
    --enable-widec \
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
    mv -v /usr/lib/libncursesw.so.6* /lib
    ln -sfv ../../lib/$(readlink /usr/lib/libncursesw.so) /usr/lib/libncursesw.so

    for lib in ncurses form panel menu ; do
        rm -vf                    /usr/lib/lib${lib}.so
        echo "INPUT(-l${lib}w)" > /usr/lib/lib${lib}.so
        ln -sfv ${lib}w.pc        /usr/lib/pkgconfig/${lib}.pc
    done

    rm -vf                     /usr/lib/libcursesw.so
    echo "INPUT(-lncursesw)" > /usr/lib/libcursesw.so
    ln -sfv libncurses.so      /usr/lib/libcurses.so

    mkdir -v /usr/share/doc/ncurses-6.2
    cp -v -R doc/* /usr/share/doc/ncurses-6.2
}

install_file 2>&1 | tee -a ${LOG_DIR}/${FILE_NAME}-install.log

