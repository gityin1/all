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

status1="未安装"
status2="未运行"
    if [[ -f /usr/bin/ddns ]]; then
        status1="已安装"
    fi
    #temp=$(systemctl status x-ui | grep Active | awk '{print $3}' | cut -d "(" -f2 | cut -d ")" -f1)
    ddnsstatus=$(ps -ef | grep "ddns" | grep -v "grep" | awk '{print $2}')
    if [[ x"${ddnsstatus}" != x"" ]]; then
        status2="已运行"
    fi

rm -rf /usr/bin/ddns
wget -N --no-check-certificate -O /usr/bin/ddns https://raw.fastgit.org/ppoonk/all/master/ddns-deploy.sh
chmod +x /usr/bin/ddns

    Download_deploy_ddns_go() {
    Install_base
    local arch1=""
    if [[ $arch == "x86_64" || $arch == "x64" || $arch == "amd64" ]]; then
        arch1="x86_64"
    elif [[ $arch == "aarch64" || $arch == "arm64" ]]; then
        arch1="arm64"
    elif [[ $arch == "arm"  || $arch == "armv7" || $arch == "armv6" || $arch == "armv7l" ]]; then
        arch1="armv6"
    elif [[ $arch == "i386"  ]]; then
        arch1="i386"
    else
        red "不支持的arch" && exit 1
    fi

    if [[ -f /usr/local/ddns.tar.gz ]]; then
        yellow "ddns-go已下载"
    else
        yellow "正在从github下载，请耐心等待······"
        wget -N --no-check-certificate -O /usr/local/ddns.tar.gz https://download.fastgit.org/jeessy2/ddns-go/releases/download/v3.7.2/ddns-go_3.7.2_Linux_${arch1}.tar.gz
        #wget -N --no-check-certificate -O /usr/local/ddns.tar.gz https://github.com/jeessy2/ddns-go/releases/download/v3.7.2/ddns-go_3.7.2_Linux_${arch1}.tar.gz
    fi
    rm -rf /usr/local/ddns-go
    mkdir /usr/local/ddns-go
    tar zxvf ddns.tar.gz -C  /usr/local/ddns-go
    rm -rf /usr/local/ddns.tar.gz
}
    Start_deploy_ddns() {
  
        cd /usr/local/ddns-go
        screen -USdm ddns ./ddns-go   
        yellow "ddns已启动"

    }
    Stop_deploy_ddns() {
        screen -S x-ui -X quit
        status=$(ps -ef | grep "ddns-go" | grep -v "grep" | awk '{print $2}')
        kill -9 $status
        yellow "ddns已停止"
    }

    Uninstall_deploy_ddns() {
        Stop_deploy_ddns
        yellow "正在卸载..."
        rm -rf /usr/local/ddns-go
        yellow "ddns卸载完成"

    }
    clear
    echo -e "
    DDNS状态：${green}$status1  $status2${plain}"
    yellow "
        1.安装ddns
        2.启动ddns(安卓deploy)
        3.停止ddns(安卓deploy)
        4.卸载ddns(安卓deploy)
        5.回车取消"
    read -p "选择序号：" input
    case $input in
        1) Download_deploy_ddns_go && Start_deploy_ddns ;;
        2) Start_deploy_ddns ;;
        3) Stop_deploy_ddns ;;
        4) Uninstall_deploy_ddns ;;
        5) exit 0 ;;
    esac
