#!/bin/bash

FILE_NAME=$(basename $0 | sed "s/\.sh//g")
OSS_NAME=xz
OSS_VER=5.2.4
OSS=$(ls ${OSS_NAME}-${OSS_VER}.tar*)

LOG_DIR=/log/ch6
mkdir -p ${LOG_DIR}
rm ${LOG_DIR}/${FILE_NAME}*

echo "delete ${OSS_NAME}-${OSS_VER}"
rm -rf ${OSS_NAME}-${OSS_VER}

# extract package, $1 is package name
function extract_package()
{
    package=$1
    package_basename=$(basename $package)

    if [[ ! -f $package ]]; then
        echo "file $package not exits, please check!!!"
        exit 1
    fi

    if [[ $package == *.tar.xz ]]; then
        TAR_OPT="-Jxvf"
    elif [[ $package == *.tar.gz ]]; then
        TAR_OPT="-zxvf"
    else
        echo "tar has no suitable options, please check"
        exit 1
    fi
    echo "extract $package"
    tar $TAR_OPT $package > ${LOG_DIR}/${FILE_NAME}-${package_basename}.log 2>&1
    if [ $? -ne 0 ]; then
        echo "tar $TAR_OPT $package fail, please check ${LOG_DIR}/${FILE_NAME}-${package_basename}.log"
        exit 1
    fi
}

extract_package $OSS

echo "enter ${OSS_NAME}-${OSS_VER}"
cd ${OSS_NAME}-${OSS_VER}
if [ $? -ne 0 ]; then
    echo "enter fail, please check"
    exit 1
fi

#######################################
# compile instructions that from book
#######################################

echo "start configure"
./configure                          \
    --prefix=/usr                    \
    --disable-static                 \
    --docdir=/usr/share/doc/xz-5.2.4 \
    > ${LOG_DIR}/${FILE_NAME}-configure.log 2>&1
if [ $? -ne 0 ]; then
    echo "configure error, please check ${LOG_DIR}/${FILE_NAME}-configure.log"
    exit 1
fi

echo "start make"
make -j8 > ${LOG_DIR}/${FILE_NAME}-make.log 2>&1
if [ $? -ne 0 ]; then
    echo "make error, please check ${LOG_DIR}/${FILE_NAME}-make.log"
    exit 1
fi

echo "start make check"
make check -j8 > ${LOG_DIR}/${FILE_NAME}-make-check.log 2>&1
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

function install()
{
    mv -v /usr/bin/{lzma,unlzma,lzcat,xz,unxz,xzcat} /bin
    mv -v /usr/lib/liblzma.so.* /lib
    ln -svf ../../lib/$(readlink /usr/lib/liblzma.so) /usr/lib/liblzma.so
}

install \
    2>&1 | tee -a ${LOG_DIR}/${FILE_NAME}-make-install.log
