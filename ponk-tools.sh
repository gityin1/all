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
virt=$( systemd-detect-virt )

# OS
<<!EOF!
[ -f /etc/redhat-release ] && awk '{print $0}' /etc/redhat-release && return
[ -f /etc/os-release ] && awk -F'[= "]' '/PRETTY_NAME/{print $3,$4,$5}' /etc/os-release && return
[ -f /etc/lsb-release ] && awk -F'[="]+' '/DESCRIPTION/{print $2}' /etc/lsb-release && return
!EOF!

OS=""
if  [ -f /etc/os-release ]; then
    OS=$(awk -F'[= "]' '/PRETTY_NAME/{print $3}' /etc/os-release)
elif [ -f /etc/redhat-release ]; then
    OS=$(awk '{print $1}' /etc/redhat-release)
elif [ -f /etc/lsb-release ]; then
    OS=$(awk -F'[="]+' '/DESCRIPTION/{print $2}' /etc/lsb-release)
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
[[ $EUID -ne 0 ]] && echo -e red "错误：必须使用root用户运行此脚本！\n" && exit 1
# 下载脚本
Add_Shell() {
    wget -O /usr/bin/ponk -N --no-check-certificate https://raw.githubusercontent.com/ppoonk/all/master/ponk-tools.sh
    chmod +x /usr/bin/ponk
   
}

# 返回主菜单
Return_Show_Menu() {
    yellow "按回车返回主菜单: " && read temp
    Show_Menu
}
# 显示info
Show_Information() {
    blue "————————————————————————————————————————————————————————————————————————————————————————————————————————"
    echo -e ""
    echo -e "OS:$(blue "$OS" $lbit位)   Arch：$(blue "$arch")   虚拟化：$(blue "$virt")"   
    echo -e ""
    blue "————————————————————————————————————————————————————————————————————————————————————————————————————————"
}
# 菜单
Show_Menu() {
    clear
    clear
    Show_Information
    yellow "直接在命令行输入ponk即可运行本脚本。请输入需要执行的序号："
    echo -e ""
    yellow "11.国内机更换github hosts"
    yellow "12.bench.sh"          
    yellow "13.三网测速 "           
    yellow "4.路由回程测试"             
    yellow "15.warp"
    echo -e ""
    yellow "21.x-ui"
    yellow "22.mack-a八合一脚本"
    yellow "23.CloudFlare Argo Tunnel隧道"
    yellow "24.BBR"
    yellow "25.BBr for openvz"
    yellow "26.下载XrayR"
    echo -e ""
    yellow "31.ServerStatus-Hotaru服务端"
    yellow "32.ServerStatus-Hotaru客户端"
    echo -e ""
    yellow "41.安装宝塔770"
    yellow "42.将xxx写入systemctl服务"
    echo -e ""
    yellow "52.卸载apache2"
    yellow "0.回车或输入0退出"
    echo -e ""
    read -p "请输入脚本序号:" Input
    
    case "$Input" in
        0) exit 0 ;;
        11) sed -i "/# GitHub520 Host Start/Q" /etc/hosts && curl https://raw.hellogithub.com/hosts >> /etc/hosts ;;
        12) curl -so- 86.re/bench.sh | bash ;;
        13) bash <(curl -Lso- https://git.io/superspeed);;
        14) wget https://raw.githubusercontent.com/nanqinlang-script/testrace/master/testrace.sh && bash testrace.sh;;
        15) wget -N https://raw.githubusercontent.com/fscarmen/warp/main/menu.sh && bash menu.sh ;;
        21) bash <(curl -Ls https://raw.githubusercontent.com/vaxilu/x-ui/master/install.sh) ;;
        22) wget -P /root -N --no-check-certificate "https://raw.githubusercontent.com/mack-a/v2ray-agent/master/install.sh" && chmod 700 /root/install.sh && /root/install.sh ;;
        23) wget -N https://raw.githubusercontents.com/Misaka-blog/argo-tunnel-script/master/argo.sh && bash argo.sh ;;
        24) wget -N --no-check-certificate "https://raw.githubusercontent.com/chiakge/Linux-NetSpeed/master/tcp.sh" && chmod +x tcp.sh && ./tcp.sh ;;
        25) wget --no-cache -O lkl-haproxy.sh https://github.com/mzz2017/lkl-haproxy/raw/master/lkl-haproxy.sh && bash lkl-haproxy.sh ;;
        26) wget -O xrayr.zip https://github.com/Misaka-blog/XrayR/releases/latest/download/XrayR-linux-64.zip && unzip -d ./xrayr xrayr.zip ;;
        31) wget https://raw.githubusercontent.com/cokemine/ServerStatus-Hotaru/master/status.sh && bash status.sh s ;;
        32) wget https://raw.githubusercontent.com/cokemine/ServerStatus-Hotaru/master/status.sh && bash status.sh c ;;
        41) Install_BT;;
        42) Add_Systemctl_Service ;;
        51) curl -fsSL https://get.docker.com | bash -s docker --mirror Aliyun ;;
        52) uninstall_apache2 ;;
        
    esac

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
            apt-get --purge remove apache2 && apt-get --purge remove apache2-doc && apt-get --purge remove apache2-utils
            find /etc -name "*apache*" |xargs rm -rf && rm -rf /var/www && rm -rf /etc/libapache2-mod-jk
            yellow "卸载完成"
        #else yellow "无需卸载"
        #fi
    elif [[ $Cmd_Type == "centos" ]]; then
       # temp=$(yum list | grep httpd)
       # if [ -n temp ]; then
            systemctl stop httpd.service
            yum erase httpd.x86_64
            yellow "卸载完成"
        #else yellow "无需卸载"
    else red "请手动卸载apache"
       # fi
    fi
}
Add_Shell
Show_Menu
