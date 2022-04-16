#!/bin/bash
red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
plain='\033[0m'


install_base() {
    if [ -f /etc/debian_version ]; then
        apt install wget curl tar -y
    else
        yum install wget curl tar -y
    fi
}

install_xray() {
    if [ -n "$(pgrep xray)" ]; then
        echo -e "xray已经运行" 
    else
    cd /root/
    wget -N --no-check-certificate -O /root/xray.zip https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-arm64-v8a.zip
    unzip -do xray xray.zip
    chmod +x xray/*
    wget -N --no-check-certificate -O /root/xray/config.json https://raw.fastgit.org/ppoonk/all/master/x-ui/config.json
    echo -e ""
    echo -e ""
    echo -e "${green}在手机termux  手动运行   cd ~/xray && ./xray${plain}"
    echo -e "${green}在手机termux  control + c  退出xray${plain}"
    echo -e "${green}默认vless，协议：ws，端口：2052，uuid：674d273d-3211-4fd1-9de2-89f6846a0688${plain}"
    echo -e "${green}配置文件请修改  /root/xray/config.json${plain}"
    echo -e "${green}修改完毕请重新启动xray${plain}"
    echo -e ""
    echo -e ""
    fi        

}   

echo -e "${green}开始安装${plain}"
install_base
install_xray