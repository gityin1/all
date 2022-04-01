#!/bin/bash
echo -e "开始安装"
pkg install proot git python -y
apt install wget curl tar -y
git clone https://github.com/sqlsec/termux-install-linux
cd termux-install-linux

