#!/bin/bash

green() {
	echo -e "\033[32m\033[01m$1\033[0m"
    }

red() {
	echo -e "\033[31m\033[01m$1\033[0m"
    }

yellow() {
	echo -e "\033[33m\033[01m$1\033[0m"
    }

blue() {
    echo -e "\033[36m\033[01m$1\033[0m"
    }

Get_Cmd_Type() {
        if [[ $(command -v apt-get) ]]; then
    Cmd_Type="apt"
    elif [[ $(command -v yum) ]]; then
        Cmd_Type="yum"
    else red "只支持debian与centos"
    fi
}

Install_base() {
    if [[ x"$Cmd_Type" == x"yum" ]]; then
        yum install wget curl tar git -y
    else
        apt install  proot git python -y
    fi
}
#安卓termux安装linux
Install_Termux_Linux() {
   
    apt install proot git python -y
    #下载linux
    git clone https://gitee.com/poiuty123/termux.git && cd ~/termux && python termux-install.py
    #启动方法
    echo -e "如果安装的是debian，使用  cd ~/Termux-Linux/Debian && ./start-debian.sh
    如果安装的是ubuntu，使用  cd ~/Termux-Linux/Ubuntu && ./start-ubuntu.sh
    其他系统启动命令类似"
    #cd ~/Termux-Linux/Debian && ./start-debian.sh
}
Install_Termux_Linux