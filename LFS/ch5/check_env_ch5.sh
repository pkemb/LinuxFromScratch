#!/bin/bash

CHECK_FAIL=0

# $1: check file
# $2: target file
function check_symbolic()
{
    file_check=$1
    file_target=$2
    LINK=$(readlink -f $file_check)
    if [[ $LINK != *${file_target} ]]; then
        echo "$file_check is not symbolic to $file_target"
        CHECK_FAIL=1
    fi
}

# $1: variable
function check_variable()
{
    if [ $1 = "" ]; then
        echo "$1 is null, please check"
        CHECK_FAIL=1
    fi
}

check_symbolic /bin/sh bash
check_symbolic /usr/bin/awk gawk
check_symbolic /usr/bin/yacc bison

check_variable $LFS
check_variable $LFS_TGT

check_symbolic /tools $LFS/tools

if [ $CHECK_FAIL -eq 0 ]; then
    echo "envirment check success!!!"
fi

