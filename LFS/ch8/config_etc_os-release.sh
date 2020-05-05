#!/bin/bash

cat > /etc/os-release << "EOF"
NAME="Linux From Scratch"
VERSION="9.1"
ID=lfs
PRETTY_NAME="Linux From Scratch 9.1"
VERSION_CODENAME="<your name here>"
EOF
