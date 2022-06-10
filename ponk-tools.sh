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

# 架构arch (x86_64,x64,amd64,aarch64,arm64,arm,s390x)
arch=$(uname -m)
<<!EOF!
if [[ $arch == "x86_64" || $arch == "x64" || $arch == "amd64" ]]; then
    arch="amd64"
elif [[ $arch == "aarch64" || $arch == "arm64" ]]; then
    arch="arm64"
elif [[ $arch == "arm"  || $arch == "armv7" || $arch == "armv6" ]];then
    arch="arm"
elif [[ $arch == "s390x" ]]; then
    arch="s390x"
else
    red "未知arch"
!EOF!

# 比特位
lbit=$( getconf LONG_BIT )
# virt
virt=$( systemd-detect-virt )
# release
release=""
if  [ -f /etc/os-release ]; then
    release=$(awk -F'[= "]' '/PRETTY_NAME/{print $3}' /etc/os-release)
elif [ -f /etc/redhat-release ]; then
    release=$(awk '{print $1}' /etc/redhat-release)
elif [ -f /etc/lsb-release ]; then
    release=$(awk -F'[="]+' '/DESCRIPTION/{print $2}' /etc/lsb-release)
fi
# command
<<!EOF!
if [[ $(command -v apt-get) || $(command -v yum) ]] && [[ $(command -v systemctl) ]]; then
	if [[ $(command -v yum) ]]; then
		cmd="yum"
	fi
else echo -e "不支持你的系统" && exit 1
fi
!EOF!
Cmd_Type=""
if [[ $(command -v apt-get) ]]; then
    Cmd_Type="debian"
elif [[ $(command -v yum) ]]; then
    Cmd_Type="centos"
else red "只支持debian与centos"
fi

# 检测是否运行
check_status() {
    count=$(ps -ef | grep "$1" | grep -v "grep" | wc -l)
    if [[ count -ne 0 ]]; then
        return 1
    else
        return 0
    fi
}

# 检测是否为服务
check_enabled() {
    temp=$(systemctl is-enabled $1)
    if [[ x"${temp}" == x"enabled" ]]; then
        return 1
    else
        return 0
    fi
}

# check root
#[[ $EUID -ne 0 ]] && red "错误：必须使用root用户运行此脚本！\n" && exit 1
# 下载脚本
#Add_Shell() {
#   wget -O /usr/bin/ponk -N --no-check-certificate https://raw.githubusercontent.com/ppoonk/all/master/ponk-tools.sh
#   chmod +x /usr/bin/ponk
#   }

# 返回主菜单
Return_Show_Menu() {
    yellow "按回车返回主菜单: " && read temp
    Show_Menu
}
# 显示info
Show_Information() {
    blue "————————————————————————————————————————————————————————————————————————————————————————————————————————"
   
    echo -e "系统:$(blue "$release" $lbit位)  Arch：$(blue "$arch")  虚拟化：$(blue "$virt") 已用ram："   

    blue "————————————————————————————————————————————————————————————————————————————————————————————————————————"
}

# 添加服务
Add_Systemctl_Service() {

    read -p "输入服务名字，如：ddns :" Name
    rm -rf /etc/systemd/system/$Name.service
    read -p "请输入运行目录，如：/root/DDNS :" WorkingDirectory
    read -p "请输入可执行文件的绝对路径，如：/root/DDNS/ddns :" ExecStart
    echo -e "[Unit]\nDescription=$name Service\nAfter=network.target\nWants=network.target\n\n[Service]\nType=simple\nWorkingDirectory=$WorkingDirectory\nExecStart=$ExecStart\n\n[Install]\nWantedBy=multi-user.target" > /etc/systemd/system/$Name.service
    systemctl daemon-reload
    systemctl enable $Name
    systemctl start $Name
    yellow "$Name 服务状态如下："
    systemctl status $Name

}

# 安装宝塔
Install_BT() {
    wget -O install.sh http://download.bt.cn/install/install-ubuntu_6.0.sh && sudo bash install.sh
    wget http://download.bt.cn/install/update/LinuxPanel-7.7.0.zip && unzip LinuxPanel-7.7.0.zip
    cd /root/panel && bash update.sh
    mv /www/server/panel/data/bind.pl bind.pl1
    bt
}

# 卸载apache2
uninstall_apache2() {
    
    if [[ $Cmd_Type == "debian" ]]; then
        #temp=$(dpkg -l | grep apache2)
        #if [ -n temp ]; then
            systemctl stop httpd.service
            apt-get --purge remove apache2 -y && apt-get --purge remove apache2-doc -y && apt-get --purge remove apache2-utils -y
            find /etc -name "*apache*" |xargs rm -rf && rm -rf /var/www && rm -rf /etc/libapache2-mod-jk
            yellow "卸载完成"
        #else yellow "无需卸载"
        #fi
    elif [[ $Cmd_Type == "centos" ]]; then
       # temp=$(yum list | grep httpd)
       # if [ -n temp ]; then
            systemctl stop httpd.service
            yum erase httpd.x86_64 -y
            yellow "卸载完成"
        #else yellow "无需卸载"
    else red "请手动卸载apache"
       # fi
    fi
}

Install_xui_cn() {
    local arch1=""
if [[ $arch == "x86_64" || $arch == "x64" || $arch == "amd64" ]]; then
    arch1="amd64"
elif [[ $arch == "aarch64" || $arch == "arm64" ]]; then
    arch1="arm64"
elif [[ $arch == "s390x" ]]; then
    arch1="s390x"
else
    arch1="amd64"
    red "检测架构失败，使用默认架构: ${arch}"
fi

echo "架构: ${arch1}"

if [ $(getconf WORD_BIT) != '32' ] && [ $(getconf LONG_BIT) != '64' ]; then
    echo "本软件不支持 32 位系统(x86)，请使用 64 位系统(x86_64)，如果检测有误，请联系作者"
    exit -1
fi


install_base() {
    if [[ x"$Cmd_Type" == x"centos" ]]; then
        yum install wget curl tar -y
    else
        apt install wget curl tar -y
    fi
}
config_after_install() {
    yellow "出于安全考虑，安装完成后需要强制修改端口与账户密码"
    read -p "请设置您的账户名:" config_account
    yellow "您的账户名将设定为:${config_account}"
    read -p "请设置您的账户密码:" config_password
    yellow "您的账户密码将设定为:${config_password}$"
    read -p "请设置面板访问端口:" config_port
    yellow "您的面板访问端口将设定为:${config_port}"
    read -p "确认设定完成？[y/n]": config_confirm
    if [[ x"${config_confirm}" == x"y" || x"${config_confirm}" == x"Y" ]]; then
        yellow "确认设定,设定中"
        /usr/local/x-ui/x-ui setting -username ${config_account} -password ${config_password}
        yellow "账户密码设定完成"
        /usr/local/x-ui/x-ui setting -port ${config_port}
        yellow "面板端口设定完成"
    else
        red "已取消,所有设置项均为默认设置,请及时修改"
    fi
}
install_x-ui() {
    systemctl stop x-ui
    cd /usr/local/
    url="https://download.fastgit.org/vaxilu/x-ui/releases/latest/download/x-ui-linux-${arch1}.tar.gz"
    echo -e "开始安装 x-ui v"
    wget -N --no-check-certificate -O /usr/local/x-ui-linux-${arch1}.tar.gz ${url}
    if [[ -e /usr/local/x-ui/ ]]; then
        rm /usr/local/x-ui/ -rf
    fi
    tar zxvf x-ui-linux-${arch1}.tar.gz
    rm x-ui-linux-${arch1}.tar.gz -f
    cd x-ui
    chmod +x x-ui bin/xray-linux-${arch1}
    cp -f x-ui.service /etc/systemd/system/
    wget --no-check-certificate -O /usr/bin/x-ui https://raw.fastgit.org/vaxilu/x-ui/main/x-ui.sh
    chmod +x /usr/local/x-ui/x-ui.sh
    chmod +x /usr/bin/x-ui
    config_after_install

    systemctl daemon-reload
    systemctl enable x-ui
    systemctl start x-ui
    echo -e "x-ui 安装完成，面板已启动，"
    echo -e ""
    echo -e "x-ui 管理脚本使用方法: "
    echo -e "----------------------------------------------"
    echo -e "x-ui              - 显示管理菜单 (功能更多)"
    echo -e "x-ui start        - 启动 x-ui 面板"
    echo -e "x-ui stop         - 停止 x-ui 面板"
    echo -e "x-ui restart      - 重启 x-ui 面板"
    echo -e "x-ui status       - 查看 x-ui 状态"
    echo -e "x-ui enable       - 设置 x-ui 开机自启"
    echo -e "x-ui disable      - 取消 x-ui 开机自启"
    echo -e "x-ui log          - 查看 x-ui 日志"
    echo -e "x-ui v2-ui        - 迁移本机器的 v2-ui 账号数据至 x-ui"
    echo -e "x-ui update       - 更新 x-ui 面板"
    echo -e "x-ui install      - 安装 x-ui 面板"
    echo -e "x-ui uninstall    - 卸载 x-ui 面板"
    echo -e "----------------------------------------------"
}  

yellow "开始安装"
install_base
install_x-ui
}


# 安装xraya
Install_Xraya() {
    #local arch=$(uname -m)
    local arch1=""
    local arch2=""
    if [[ $arch == "x86_64" || $arch == "x64" || $arch == "amd64" ]]; then
        arch1="x64"
        arch2="64"
    elif [[ $arch == "aarch64" || $arch == "arm64" ]]; then
        arch1="arm64"
        arch2="arm64-v8a"
    elif [[ $arch == "arm"  || $arch == "armv7" || $arch == "armv6" ]]; then
        arch1="arm"
        arch2="arm32-v7a"
    else
        red "不支持的arch" && exit 1
    fi

    wget -N --no-check-certificate -O /root/xray.zip https://download.fastgit.org/XTLS/Xray-core/releases/download/latest/Xray-linux-${arch2}.zip
    unzip -d ./xray -o xray.zip
    #rm -f xray.zip
    chmod +x xray/*
    mv xray/xray /usr/local/bin/xray
    mv xray /usr/local/share/
    mkdir  /usr/local/xraya
    wget -N --no-check-certificate -O /usr/local/xraya/xraya https://download.fastgit.org/v2rayA/v2rayA/releases/download/v1.5.7/v2raya_linux_${arch1}_1.5.7
    chmod +x /usr/local/xraya/xraya
    # 添加service
    Name="xraya"
    rm -rf /etc/systemd/system/$Name.service
    WorkingDirectory="/usr/local/xraya"
    ExecStart="/usr/local/xraya/xraya"
    echo -e "[Unit]\nDescription=$name Service\nAfter=network.target
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
    yellow "使用方法 systemctl [start|restart|stop|status] $Name 
    $Name服务状态如下："
    systemctl status $Name
}


#安装DDNS-GO
Install_DDNS() {

    local arch1=""
    if [[ $arch == "x86_64" || $arch == "x64" || $arch == "amd64" ]]; then
        arch1="x86_64"
    elif [[ $arch == "aarch64" || $arch == "arm64" ]]; then
        arch1="arm64"
    elif [[ $arch == "arm"  || $arch == "armv7" || $arch == "armv6" ]]; then
        arch1="armv6"
    elif [[ $arch == "i386"  ]]; then
        arch1="i386"
    else
        red "不支持的arch" && exit 1
    fi
    yellow "正在从github下载，请耐心等待······"
    wget -N --no-check-certificate -O /root/ddns.tar.gz https://download.fastgit.org/jeessy2/ddns-go/releases/download/v3.7.0/ddns-go_3.7.0_Linux_${arch1}.tar.gz
    mkdir /usr/local/ddns-go
    tar zxvf ddns.tar.gz -C  /usr/local/ddns-go
    rm -f /root/ddns.tar.gz
    #cd /root/ddns
    #sudo ./ddns-go -s install
    # 添加service
    systemctl stop ddns-go
    local Name="ddns-go"
    rm -rf /etc/systemd/system/$Name.service
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
    systemctl status $Name
    check_status "ddns-go"
        if [[ $? == 1 ]]; then
            yellow "ddns已在运行,访问ip:9876即可访问ddns-go面板
使用方法 systemctl [start|restart|stop|status] ddns-go"
        else red "安装错误,重新运行脚本多尝试几次" && exit 1
    fi
}



# 安装v2board面板
Install_V2board() {
    if [[ $Cmd_Type == "centos" ]]; then
        yum -y install git wget 
        git clone https://gitee.com/gz1903/v2board_install.git /usr/local/src/v2board_install 
        cd /usr/local/src/v2board_install && chmod +x v2board_install.sh && ./v2board_install.sh
        
    else 
        red "仅支持centos系统！！！"
    fi

}

Install_Termux_Linux() {
   
    apt install proot git python -y
    #下载linux
    git clone https://gitee.com/poiuty123/termux.git && cd ~/termux && python termux-install.py
    #启动方法
    echo -e "如果安装的是debian，使用  cd ~/Termux-Linux/Debian && ./start-debian.sh
    如果安装的是ubuntu，使用  cd ~/Termux-Linux/Ubuntu && ./start-ubuntu.sh
    其他系统启动命令类似"

    cd ~/Termux-Linux/Debian && ./start-debian.sh
}

# 菜单
Show_Menu() {
    clear
    clear
#   Show_Information
    yellow "直接在命令行输入ponk即可运行本脚本。请输入需要执行的序号："
    echo -e ""
    yellow "11.国内机更换github hosts"
    yellow "12.bench.sh"          
    yellow "13.三网测速 "           
    yellow "14.路由回程测试"             
    yellow "15.warp"
    echo -e ""
    yellow "21.安装x-ui"
    yellow "22.安装x-ui国内机适用"
    yellow "23.mack-a八合一脚本"
    yellow "24.CloudFlare Argo Tunnel隧道"
    yellow "25.BBR"
    yellow "26.BBr for openvz"
    yellow "27.下载XrayR"
    yellow "28.安装xraya面板"
    yellow "29.安装DDNS-GO"
    echo -e ""
    yellow "31.ServerStatus-Hotaru服务端"
    yellow "32.ServerStatus-Hotaru客户端"
    echo -e ""
    yellow "41.安装宝塔770"
    yellow "42.将xxx写入systemctl服务"
    yellow "43.安装docker"
    yellow "44.安装v2board面板"
    echo -e ""
    yellow "52.卸载apache2"
    yellow "53.安卓termux安装linux"
    yellow "0.回车或输入0退出"
    echo -e ""
    read -p "请输入脚本序号:" Input
    
    case "$Input" in
        0) exit 0 ;;
        11) sed -i "/# GitHub520 Host Start/Q" /etc/hosts && curl https://raw.hellogithub.com/hosts >> /etc/hosts ;;
        12) curl -so- 86.re/bench.sh | bash ;;
        13) bash <(curl -Lso- https://git.io/Jlkmw);;
        14) wget https://raw.githubusercontent.com/nanqinlang-script/testrace/master/testrace.sh && bash testrace.sh;;
        15) wget -N https://raw.githubusercontent.com/fscarmen/warp/main/menu.sh && bash menu.sh ;;
        21) bash <(curl -Ls https://raw.githubusercontent.com/vaxilu/x-ui/master/install.sh) ;;
        22) Install_xui_cn ;;
        23) wget -P /root -N --no-check-certificate "https://raw.githubusercontent.com/mack-a/v2ray-agent/master/install.sh" && chmod 700 /root/install.sh && /root/install.sh ;;
        24) wget -N https://raw.githubusercontents.com/Misaka-blog/argo-tunnel-script/master/argo.sh && bash argo.sh ;;
        25) wget -N --no-check-certificate "https://raw.githubusercontent.com/chiakge/Linux-NetSpeed/master/tcp.sh" && chmod +x tcp.sh && ./tcp.sh ;;
        26) wget --no-cache -O lkl-haproxy.sh https://github.com/mzz2017/lkl-haproxy/raw/master/lkl-haproxy.sh && bash lkl-haproxy.sh ;;
        27) wget -O xrayr.zip https://github.com/Misaka-blog/XrayR/releases/latest/download/XrayR-linux-64.zip && unzip -d ./xrayr xrayr.zip ;;
        28) Install_Xraya ;;
        29) Install_DDNS ;;
        31) wget https://raw.githubusercontent.com/cokemine/ServerStatus-Hotaru/master/status.sh && bash status.sh s ;;
        32) wget https://raw.githubusercontent.com/cokemine/ServerStatus-Hotaru/master/status.sh && bash status.sh c ;;
        41) Install_BT;;
        42) Add_Systemctl_Service ;;
        43) curl -fsSL https://get.docker.com | bash -s docker --mirror Aliyun ;;
        44) Install_V2board ;;
        51) curl -fsSL https://get.docker.com | bash -s docker --mirror Aliyun ;;
        52) uninstall_apache2 ;;
        53) Install_Termux_Linux ;;
        
    esac

}
# Add_Shell
Show_Menu
