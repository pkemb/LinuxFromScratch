#!/bin/bash

FILE_NAME=$(basename $0 | sed "s/\.sh//g")
OSS_NAME=meson
OSS_VER=0.53.1
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

echo "start compile"
python3 setup.py build \
    > ${LOG_DIR}/${FILE_NAME}-compile.log 2>&1
if [ $? -ne 0 ]; then
    echo "compile error, please check ${LOG_DIR}/${FILE_NAME}-compile.log"
    exit 1
fi

function install_file()
{
    echo "start manual install file"
    python3 setup.py install --root=dest
    cp -rv dest/* /
}

install_file >> ${LOG_DIR}/${FILE_NAME}-install.log 2>&1

