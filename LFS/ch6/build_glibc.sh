#!/bin/bash

FILE_NAME=$(basename $0 | sed "s/\.sh//g")
OSS_NAME=glibc
OSS_VER=2.31
OSS=${OSS_NAME}-${OSS_VER}.tar.xz

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

echo "start patch"
patch -Np1 -i ../glibc-2.31-fhs-1.patch > ${LOG_DIR}/${FILE_NAME}-patch.log 2>&1

case $(uname -m) in
    i?86)    ln -sfv ld-linux.so.2 /lib/ld-lsb.so.3
    ;;
    x86_64)  ln -sfv ../lib/ld-linux-x86-64.so.2 /lib64
             ln -sfv ../lib/ld-linux-x86-64.so.2 /lib64/ld-lsb-x86-64.so.3
    ;;
esac

mkdir -v build
cd build

echo "start configure"
CC="gcc -ffile-prefix-map=/tools=/usr"         \
../configure                                   \
    --prefix=/usr                              \
    --disable-werror                           \
    --enable-kernel=3.2                        \
    --enable-stack-protector=strong            \
    --with-headers=/usr/include                \
    libc_cv_slibdir=/lib                       \
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

case $(uname -m) in
    i?86)    ln -sfnv ${PWD}/elf/ld-linux.so.2        /lib ;;
    x86_64)  ln -sfnv ${PWD}/elf/ld-linux-x86-64.so.2 /lib ;;
esac

echo "start make check"
make check -j8 > ${LOG_DIR}/${FILE_NAME}-make-check.log 2>&1
if [ $? -ne 0 ]; then
    echo "make check error, please check ${LOG_DIR}/${FILE_NAME}-make-check.log"
    #exit 1
fi

touch /etc/ld.so.conf

sed '/test-installation/s@$(PERL)@echo not running@' -i ../Makefile

echo "start make install"
make install > ${LOG_DIR}/${FILE_NAME}-make-install.log 2>&1
if [ $? -ne 0 ]; then
    echo "make install error, please check ${LOG_DIR}/${FILE_NAME}-make-install.log"
    exit 1
fi

echo "install the configuration file"
cp -v --/nscd/nscd.conf /etc/nscd.conf
mkdir -pv /var/cache/nscd

echo "install the locales"
mkdir -pv /usr/lib/locale
localedef -i POSIX -f UTF-8 C.UTF-8 2> /dev/null || true
localedef -i cs_CZ -f UTF-8 cs_CZ.UTF-8
localedef -i de_DE -f ISO-8859-1 de_DE
localedef -i de_DE@euro -f ISO-8859-15 de_DE@euro
localedef -i de_DE -f UTF-8 de_DE.UTF-8
localedef -i el_GR -f ISO-8859-7 el_GR
localedef -i en_GB -f UTF-8 en_GB.UTF-8
localedef -i en_HK -f ISO-8859-1 en_HK
localedef -i en_PH -f ISO-8859-1 en_PH
localedef -i en_US -f ISO-8859-1 en_US
localedef -i en_US -f UTF-8 en_US.UTF-8
localedef -i es_MX -f ISO-8859-1 es_MX
localedef -i fa_IR -f UTF-8 fa_IR
localedef -i fr_FR -f ISO-8859-1 fr_FR
localedef -i fr_FR@euro -f ISO-8859-15 fr_FR@euro
localedef -i fr_FR -f UTF-8 fr_FR.UTF-8
localedef -i it_IT -f ISO-8859-1 it_IT
localedef -i it_IT -f UTF-8 it_IT.UTF-8
localedef -i ja_JP -f EUC-JP ja_JP
localedef -i ja_JP -f SHIFT_JIS ja_JP.SIJS 2> /dev/null || true
localedef -i ja_JP -f UTF-8 ja_JP.UTF-8
localedef -i ru_RU -f KOI8-R ru_RU.KOI8-R
localedef -i ru_RU -f UTF-8 ru_RU.UTF-8
localedef -i tr_TR -f UTF-8 tr_TR.UTF-8
localedef -i zh_CN -f GB18030 zh_CN.GB18030
localedef -i zh_HK -f BIG5-HKSCS zh_HK.BIG5-HKSCS

make localedata/install-locales > ${LOG_DIR}/${FILE_NAME}-install-locales.log 2>&1
if [ $? -ne 0 ]; then
    echo "make localedata fail, please check ${LOG_DIR}/${FILE_NAME}-install-locales.log"
    exit 1
fi

if [ ! -f /etc/nsswitch.conf ]; then
    echo "adding nsswitch.conf"
    echo "passwd: files" > /etc/nsswitch.conf
    echo "group: files" >> /etc/nsswitch.conf
    echo "shadow: files" >> /etc/nsswitch.conf
    echo "hosts: files" >> /etc/nsswitch.conf
    echo "networks: files" >> /etc/nsswitch.conf
    echo "protocols: files" >> /etc/nsswitch.conf
    echo "services: files" >> /etc/nsswitch.conf
    echo "ethers: files" >> /etc/nsswitch.conf
    echo "rpc: files" >> /etc/nsswitch.conf
fi

echo "adding time zone data"

extract_package ../../tzdata2019c.tar.gz

ZONEINFO=/usr/share/zoneinfo
mkdir -pv $ZONEINFO/{posix,right}
for tz in etcetera southamerica northamerica europe africa antarctica \
          asia australasia backward pacificnew systemv; do
    zic -L /dev/null -d $ZONEINFO ${tz}
    zic -L /dev/null -d $ZONEINFO/posix ${tz}
    zic -L leapseconds -d $ZONEINFO/right ${tz}
done

cp -v zone.tab zone1970.tab iso3166.tab $ZONEINFO
zic -d $ZONEINFO -p America/New_York
unset ZONEINFO

#echo "create /etc/localtime"
#ln -sfv /usr/share/zoneinfo

if [ ! -f /etc/ld.so.conf ]; then
    echo "start configuring /etc/ld.so.conf"
    echo "/usr/local/lib" > /etc/ld.so.conf
    echo "/opt/lib" >> /etc/ld.so.conf
    echo "include /etc/ld.so.conf.d/*.conf" >> /etc/ld.so.conf
fi


