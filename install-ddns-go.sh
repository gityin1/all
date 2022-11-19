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

arch=$(uname -m)
# 获取command类型
Get_Cmd_Type() {
    if [[ $(command -v apt-get) ]]; then
    Cmd_Type="apt"
    elif [[ $(command -v yum) ]]; then
        Cmd_Type="yum"
    else red "只支持debian与centos"
    fi
}
Install_base() {
    Get_Cmd_Type
    if [[ x"$Cmd_Type" == x"yum" ]]; then
        yum install wget curl tar -y
    else
        apt install wget curl tar -y
    fi
}
# 检测是否后台运行， 返回0为运行
check_status() {
    count=$(ps -ef | grep "$1" | grep -v "grep" | wc -l)
    if [[ count -ne 0 ]]; then
        return 0
    else
        return 1
    fi
}

Install_DDNS_go_linux() {
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

    if [[ -s /root/ddns.tar.gz ]]; then
        yellow "ddns-go已下载"
    else
        yellow "正在从github下载，请耐心等待······"
        wget -N --no-check-certificate -O /root/ddns.tar.gz https://download.fastgit.org/jeessy2/ddns-go/releases/download/v3.7.0/ddns-go_3.7.0_Linux_${arch1}.tar.gz
    fi
    mkdir /usr/local/ddns-go
    tar zxvf ddns.tar.gz -C  /usr/local/ddns-go
    #rm -f /root/ddns.tar.gz
    # 添加service
    systemctl stop ddns-go
    local Name="ddns-go"
    WorkingDirectory="/usr/local/$Name"
    ExecStart="/usr/local/$Name/$Name"
    echo -e "[Unit]\nDescription=$Name Service\nAfter=network.target
    Wants=network.target

    [Service]
    Type=simple
    WorkingDirectory=$WorkingDirectory
    ExecStart=$ExecStart

    [Install]
    WantedBy=multi-user.target" > /etc/systemd/system/$Name.service
    systemctl daemon-reload
    systemctl enable $Name
    systemctl start $Name
    
    check_status "ddns-go"
        if [[ $? == 0 ]]; then
            yellow "
            ddns-go已在运行,访问ip:9876即可访问ddns-go面板
            使用方法 systemctl [start|restart|stop|status] ddns-go"
        else red "安装错误,重新运行脚本多尝试几次" && exit 1
        fi
}
Install_DDNS_go_deploy() {
    
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
        wget -N --no-check-certificate -O /usr/local/ddns.tar.gz https://github.com/jeessy2/ddns-go/releases/download/v3.7.2/ddns-go_3.7.2_Linux_${arch1}.tar.gz
    fi
    rm -rf /usr/local/ddns-go
    mkdir /usr/local/ddns-go
    tar zxvf ddns.tar.gz -C  /usr/local/ddns-go
    rm -rf /usr/local/ddns.tar.gz

    }
    Start_deploy_ddns_go() {
        apt install screen -y
        cd /usr/local/ddns-go
        screen -USdm ddns ./ddns-go
        yellow "ddns-已启动,访问IP:9876 即可管理ddns动态域名解析"
    }
    Stop_deploy_ddns_go() {
        screen -S ddns -X quit
        ddnsstatus=$(ps -ef | grep "ddns" | grep -v "grep" | awk '{print $2}')
        kill -9 $ddnsstatus
        yellow "ddns已停止"
    }

    Uninstall_deploy_ddns_go() {
        Stop_deploy_ddns_go
        yellow "正在卸载..."
        rm -rf /usr/bin/ddns
        rm -rf /usr/local/ddns-go
        rm -rf /root/.ddns_go_config.yaml
        yellow "ddns-go卸载完成"

    }
    clear
    yellow "
        1.安装ddns-go(安卓deploy)
        2.卸载ddns-go(安卓deploy)
        3.回车取消"
    read -p "选择序号：" deploy_ddns_go_input
    case $deploy_ddns_go_input in
        1) Download_deploy_ddns_go && Start_deploy_ddns_go ;;
        2) Uninstall_deploy_ddns_go ;;
        3) exit 0 ;;
    esac

    
}

Uninstall_DDNS_go_linux() {
    yellow "正在卸载..."
    systemctl stop ddns-go
    rm -rf /etc/systemd/system/ddns-go.service
    rm -rf /usr/local/ddns-go
    rm -rf /root/.ddns_go_config.yaml
    yellow "ddns-go卸载完成"

}
menu() {
        clear
    yellow "
        1.linux安装ddns-go
        2.linux卸载ddns-go
        3.安卓deploy安装ddns
        4.回车取消"
    read -p "选择序号：" DDNS_go_input
    case $DDNS_go_input in
        1) Install_DDNS_go_linux ;;
        2) Uninstall_DDNS_go_linux ;;
        3) Install_DDNS_go_deploy ;;
        *) exit 0 ;;
    esac
}
menu

