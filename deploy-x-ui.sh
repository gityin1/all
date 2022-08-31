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

red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
plain='\033[0m'

# check root
[[ $EUID -ne 0 ]] && echo -e "${red}错误：${plain} 必须使用root用户运行此脚本！\n" && exit 1

arch=$(uname -m)

# 比特位
Get_bit() {
    lbit=$( getconf LONG_BIT )
}


Get_Cmd_Type() {
        if [[ $(command -v apt-get) ]]; then
    Cmd_Type="apt"
    elif [[ $(command -v yum) ]]; then
        Cmd_Type="yum"
    else red "只支持debian与centos"
    fi
    }
Get_Release() {
    if [[ -f /etc/redhat-release ]]; then
        release="centos"
    elif cat /etc/issue | grep -Eqi "debian"; then
        release="debian"
    elif cat /etc/issue | grep -Eqi "ubuntu"; then
        release="ubuntu"
    elif cat /etc/issue | grep -Eqi "centos|red hat|redhat"; then
        release="centos"
    elif cat /proc/version | grep -Eqi "debian"; then
        release="debian"
    elif cat /proc/version | grep -Eqi "ubuntu"; then
        release="ubuntu"
    elif cat /proc/version | grep -Eqi "centos|red hat|redhat"; then
        release="centos"
    else
        red -e "未检测到系统版本，请联系脚本作者" && exit 1
    fi
    }

    
#安装x-ui for deploy

    Get_bit
    Download_deploy_x-ui() {

    # arm32位和arm64位下载地址
    [[ $lbit == 32 ]] && url="https://raw.fastgit.org/ppoonk/all/master/x-ui/x-ui-arm32.tar.gz"
    [[ $lbit == 64 ]] && url="https://download.fastgit.org/vaxilu/x-ui/releases/latest/download/x-ui-linux-arm64.tar.gz"
    if [[ -s /usr/local/x-ui.tar.gz ]]; then
        yellow "x-ui已下载"
    else
        yellow "正在从github下载，请耐心等待······"
        wget -N --no-check-certificate -O /usr/local/x-ui.tar.gz ${url}
    fi
    yellow "下载完成，正在解压"
    cd /usr/local/
    tar zxvf x-ui.tar.gz
    cd x-ui 
    chmod +x x-ui bin/*

    }
    Start_deploy_x-ui() {
        apt update -y
        apt install screen -y
        cd /usr/local/x-ui
        /usr/local/x-ui/x-ui setting -username admin -password admin
        screen -USdm x-ui ./x-ui
        #wget --no-check-certificate -O /usr/bin/x-ui https://raw.fastgit.org/vaxilu/x-ui/main/x-ui.sh
        #chmod +x /usr/bin/x-ui
        yellow "使用默认参数"
        yellow "x-ui已启动，访问IP:54321即可管理xui面板"
    }
    Stop_deploy_x-ui() {
        screen -S x-ui -X quit
        xuistatus=$(ps -ef | grep "x-ui" | grep -v "grep" | awk '{print $2}')
        kill -9 $xuistatus
        yellow "x-ui已停止"
    }

    Uninstall_deploy_x-ui() {
        Stop_deploy_x-ui
        yellow "正在卸载..."
        rm -rf /usr/local/x-ui
        yellow "x-ui卸载完成"

    }

    clear
    yellow "
        1.安装x-ui(安卓deploy)
        2.启动x-ui(安卓deploy)
        3.停止x-ui(安卓deploy)
        4.卸载x-ui(安卓deploy)
        5.回车取消"
    read -p "选择序号：" deploy_xui_input
    case $deploy_xui_input in
        1) Download_deploy_x-ui && Start_deploy_x-ui ;;
        2) Start_deploy_x-ui ;;
        3) Stop_deploy_x-ui ;;
        4) Uninstall_deploy_x-ui ;;
        5) exit 0 ;;
    esac



