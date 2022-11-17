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

Get_bit() {
    lbit=$( getconf LONG_BIT )
}
status1="未安装"
status2="未运行"
    if [[ -f /usr/bin/x-ui ]]; then
        status1="已安装"
    fi
    temp=$(systemctl status x-ui | grep Active | awk '{print $3}' | cut -d "(" -f2 | cut -d ")" -f1)
    if [[ x"${temp}" == x"running" ]]; then
        status2="已运行"
    fi

rm -rf /usr/bin/x-ui
#wget -N --no-check-certificate -O /usr/bin/x-ui https://github.com/ppoonk/all/master/all/x-ui-deploy.sh
wget -N --no-check-certificate -O /usr/bin/x-ui https://raw.fastgit.org/ppoonk/all/master/all/x-ui-deploy.sh
chmod +x /usr/bin/x-ui
Download_deploy_x-ui() {
    Get_bit
    apt update -y
    apt install screen -y

    # arm32位和arm64位下载地址
    [[ $lbit == 32 ]] && url="https://raw.fastgit.org/ppoonk/all/master/x-ui/x-ui-arm32.tar.gz"
    #[[ $lbit == 32 ]] && url="https://github.com/ppoonk/all/master/x-ui/x-ui-arm32.tar.gz"
    [[ $lbit == 64 ]] && url="https://download.fastgit.org/vaxilu/x-ui/releases/latest/download/x-ui-linux-arm64.tar.gz"
    #[[ $lbit == 64 ]] && url="https://github.com/vaxilu/x-ui/releases/latest/download/x-ui-linux-arm64.tar.gz"
    
     rm -rf /usr/local/x-ui.tar.gz
     rm -rf /usr/local/x-ui
    
    yellow "正在从github下载，请耐心等待······"
    wget -N --no-check-certificate -O /usr/local/x-ui.tar.gz ${url}
    
    yellow "下载完成，正在解压"
    cd /usr/local/
    tar zxvf x-ui.tar.gz
    cd x-ui 
    chmod +x x-ui bin/* 
    /usr/local/x-ui/x-ui setting -username admin -password admin
  
    wget --no-check-certificate -O /usr/bin/x-ui https://raw.fastgit.org/ppoonk/all/master/x-ui-series.sh
    chmod +x /usr/bin/x-ui
    yellow "所有文件下载完成，默认端口：54321，默认用户名admin，默认密码：admin"
    yellow "请及时修改用户名和密码"
}

Start_deploy_x-ui() {

        cd /usr/local/x-ui
        screen -USdm x-ui ./x-ui
        yellow "x-ui已启动，访问IP:端口  即可管理xui面板"
        yellow "命令行输入 x-ui 回车，可进行重启，卸载，启动等操作"
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
    
    echo -e "
    x-ui状态：${green}$status1  $status2${plain}"
    yellow "
        1.安装x-ui(安卓deploy)
        2.启动x-ui(安卓deploy)
        3.停止x-ui(安卓deploy)
        4.卸载x-ui(安卓deploy)
        5.重置用户名和密码为 admin
        6.回车取消"
    read -p "选择序号：" deploy_xui_input
    case $deploy_xui_input in
        1) Download_deploy_x-ui && Start_deploy_x-ui ;;
        2) Start_deploy_x-ui ;;
        3) Stop_deploy_x-ui ;;
        4) Uninstall_deploy_x-ui ;;
        5) /usr/local/x-ui/x-ui setting -username admin -password admin 
        yellow "用户名和密码已重置为 admin" ;;

        6) exit 0 ;;
    esac
