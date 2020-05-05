#!/bin/bash

FILE_NAME=$(basename $0 | sed "s/\.sh//g")
OSS_NAME=ninja
OSS_VER=1.10.0
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

export NINJAJOBS=4

function patch_file()
{
    echo "start patch"
    sed -i '/int Guess/a \
             int j = 0;\
             char* jobs = getenv( "NINJAJOBS" );\
             if ( jobs != NULL ) j = atoi( jobs );\
             if ( j > 0 ) return j;\
' src/ninja.cc
}

patch_file > ${LOG_DIR}/${FILE_NAME}-patch.log 2>&1

echo "start build"
python3 configure.py --bootstrap  \
    > ${LOG_DIR}/${FILE_NAME}-build.log 2>&1
if [ $? -ne 0 ]; then
    echo "build error, please check ${LOG_DIR}/${FILE_NAME}-build.log"
    exit 1
fi

echo "start test"

function ninja_test()
{
    ./ninja ninja_test
    ./ninja_test --gtest_filter=-SubprocessTest.SetWithLots
}

ninja_test \
    > ${LOG_DIR}/${FILE_NAME}-test.log 2>&1
if [ $? -ne 0 ]; then
    echo "test error, please check ${LOG_DIR}/${FILE_NAME}-test.log"
    exit 1
fi

function install_file()
{
    echo "start manual install file"
    install -vm755 ninja /usr/bin
    install -vDm644 misc/bash-completion /usr/share/bash-completion/completions/ninja
    install -vDm644 misc/zsh-completion /usr/share/zsh/site-functions/_ninja
}

install_file 2>&1 | tee -a ${LOG_DIR}/${FILE_NAME}-install.log

