#!/bin/bash

FILE_NAME=$(basename $0 | sed "s/\.sh//g")
OSS_NAME=tcl
OSS_VER=8.6.10
OSS=${OSS_NAME}${OSS_VER}-src.tar.gz

LOG_DIR=${LFS}/log/ch5
mkdir -p ${LOG_DIR}
rm ${LOG_DIR}/${FILE_NAME}*

echo "delete ${OSS_NAME}${OSS_VER}"
rm -rf ${OSS_NAME}${OSS_VER}

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

echo "enter ${OSS_NAME}${OSS_VER}"
cd ${OSS_NAME}${OSS_VER}
if [ $? -ne 0 ]; then
    echo "enter fail, please check"
    exit 1
fi

#######################################
# compile instructions that from book
#######################################

cd unix

echo "start configure"
./configure --prefix=/tools \
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

echo "start make test"
TZ=UTC make test > ${LOG_DIR}/${FILE_NAME}-make-test.log 2>&1
if [ $? -ne 0 ]; then
    echo "make error, please check ${LOG_DIR}/${FILE_NAME}-make-test.log"
    exit 1
fi

echo "start make install"
make install > ${LOG_DIR}/${FILE_NAME}-make-install.log 2>&1
if [ $? -ne 0 ]; then
    echo "make install error, please check ${LOG_DIR}/${FILE_NAME}-make-install.log"
    exit 1
fi

chmod -v u+w /tools/lib/libtcl8.6.so

echo "start make install-private-headers"
make install-private-headers > ${LOG_DIR}/${FILE_NAME}-make-install-private-headers.log 2>&1
if [ $? -ne 0 ]; then
    echo "make install error, please check ${LOG_DIR}/${FILE_NAME}-make-install-private-headers.log"
    exit 1
fi

ln -sv tclsh8.6 /tools/bin/tclsh
