#!/bin/bash

# extract package
# $1 is package name
# $2 is log file

package=$1
logfile=$2

if [[ ! "$package" ]] || [[ ! "$logfile" ]]; then
    exit 0
fi

package_basename=$(basename $package)

if [[ ! -f $package ]]; then
    echo "file $package not exits, please check!!!"
    exit 1
fi

if [[ $package == *.tar.xz ]]; then
    TAR_OPT="-Jxvf"
elif [[ $package == *.tar.gz ]]; then
    TAR_OPT="-zxvf"
elif [[ $package == *.tar.bz2 ]]; then
    TAR_OPT="-jxvf"
else
    echo "tar has no suitable options, please check"
    exit 1
fi
echo "extract $package"


tar $TAR_OPT $package > $logfile 2>&1 
if [ $? -ne 0 ]; then
    echo "tar $TAR_OPT $package fail, please check $logfile"
    exit 1
fi

exit 0

