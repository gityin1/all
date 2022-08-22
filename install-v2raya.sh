
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

 Install_V2raya() {
    Install_base
    #local arch=$(uname -m)
    local arch1=""
    local arch2=""
    if [[ $arch == "x86_64" || $arch == "x64" || $arch == "amd64" ]]; then
        arch1="x64"
        arch2="64"
    elif [[ $arch == "aarch64" || $arch == "arm64" ]]; then
        arch1="arm64"
        arch2="arm64-v8a"
    elif [[ $arch == "arm"  || $arch == "armv7" || $arch == "armv6" || $arch == "armv7l" ]]; then
        arch1="arm"
        arch2="arm32-v7a"
    else
        red "不支持的arch" && exit 1
    fi
    cd /root
    if [[ -s /root/xray.zip ]]; then
        yellow "xray内核已下载"
    else
        yellow "正在下载xray内核"
        wget -N --no-check-certificate -O /root/xray.zip https://github.com/XTLS/Xray-core/releases/download/v1.5.5/Xray-linux-${arch2}.zip
    fi
    unzip -d ./xray -o xray.zip
    chmod +x xray/*
    mv xray/xray /usr/local/bin/xray
    mv xray /usr/local/share/
    mkdir  /usr/local/v2raya
    if [[ -s /root/v2raya ]]; then
        yellow "v2raya已下载"
        mv /root/v2raya /usr/local/v2raya/v2raya
        chmod +x /usr/local/v2raya/v2raya
    else
        yellow "正在下载v2raya"
        wget -N --no-check-certificate -O /root/v2raya https://github.com/v2rayA/v2rayA/releases/download/v1.5.7/v2raya_linux_${arch1}_1.5.7
        mv /root/v2raya /usr/local/v2raya/v2raya
        chmod +x /usr/local/v2raya/v2raya
    fi

    # 添加service
    local Name="v2raya"
    WorkingDirectory="/usr/local/v2raya"
    ExecStart="/usr/local/v2raya/v2raya"
    echo -e "[Unit]\nDescription=$name Service
    After=network.target
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
    check_status "v2raya"
        if [[ $? == 0 ]]; then
            yellow "
            v2raya已在运行,访问ip:2017即可访问v2raya面板
            使用方法 systemctl [start|restart|stop|status] v2raya"
        else red "安装错误,重新运行脚本多尝试几次" && exit 1
    fi
}
Uninstall_V2raya() {
    yellow "开始卸载..."
    systemctl stop v2raya
    rm -rf /usr/local/share/xray
    rm -rf /usr/local/bin/xray
    rm -rf /usr/local/v2raya
    rm -rf /etc/systemd/v2raya.service
    systemctl daemon-reload
    yellow "v2raya卸载完成"

}
    clear
    yellow "
        1.安装v2raya
        2.卸载v2raya
        3.回车取消"
    read -p "选择序号：" V2raya_input
    case $V2raya_input in
        1) Install_V2raya ;;
        2) Uninstall_V2raya ;;
        3) exit 0 ;;
    esac
    