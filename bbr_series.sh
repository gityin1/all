#!/bin/bash

red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
plain='\033[0m'

BBR_series() {
    clear
    echo -e "${yellow}
    1.BBR
    2.BBr for openvz
    3.回车取消并退出${plain}"
    read -p "输入序号：" BBR_input
    case $BBR_input in
    1) wget -N --no-check-certificate "https://raw.githubusercontent.com/chiakge/Linux-NetSpeed/master/tcp.sh" 
    chmod +x tcp.sh && ./tcp.sh ;;
    2) wget --no-cache -O lkl-haproxy.sh https://github.com/mzz2017/lkl-haproxy/raw/master/lkl-haproxy.sh
    bash lkl-haproxy.sh ;;
    *) exit 0;;
    esac

}
BBR_series