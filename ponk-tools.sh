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
blue='\033[0;36m'
plain='\033[0m'

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
#获取release第一种方法
Get_Release() {
    if  [ -f /etc/os-release ]; then
        release=$(awk -F'[= "]' '/PRETTY_NAME/{print $3}' /etc/os-release)
    elif [ -f /etc/redhat-release ]; then
        release=$(awk '{print $1}' /etc/redhat-release)
    elif [ -f /etc/lsb-release ]; then
        release=$(awk -F'[="]+' '/DESCRIPTION/{print $2}' /etc/lsb-release)
    fi
}

#获取release第二种方法
<<!EOF!
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
!EOF!

#开放所有端口
Open_ports() {
	systemctl stop firewalld.service
	systemctl disable firewalld.service
	setenforce 0
	ufw disable
	iptables -P INPUT ACCEPT
	iptables -P FORWARD ACCEPT
	iptables -P OUTPUT ACCEPT
	iptables -t nat -F
	iptables -t mangle -F
	iptables -F
	iptables -X
	netfilter-persistent save
	yellow "VPS中的所有网络端口已开启"
}
#临时关闭SElinux
#setenforce 0
#永久关闭SElinux
#sed -i "s/SELINUX=enforcing/SELINUX=disabled/" /etc/selinux/config

#获取IP地址
Get_Ip() {
    #ipv4_address=$(curl 4.ipw.cn 2>/dev/null)
    #ipv6_address=$(curl 6.ipw.cn 2>/dev/null)
    ipv4_address=$(curl -s4m8 https://ip.gs -k)
    ipv6_address=$(curl -s6m8 https://ip.gs -k)
    
}
#获取ip地区，判断国内国外vps
Get_region() {

    #v6=$(curl -s6m8 https://ip.gs -k)
    #c6=$(curl -s6m8 https://ip.gs/country -k)
    v4=$(curl -s4m8 https://ip.gs -k)
    c4=$(curl -s4m8 https://ip.gs/country -k)
}


# 获取command类型
Get_Cmd_Type() {
        if [[ $(command -v apt-get) ]]; then
    Cmd_Type="apt"
    elif [[ $(command -v yum) ]]; then
        Cmd_Type="yum"
    else red "只支持debian与centos"
    fi
}
#安装依赖
Install_base() {
    if [[ x"$Cmd_Type" == x"yum" ]]; then
        yum install wget curl tar -y
    else
        apt install wget curl tar -y
    fi
}
# 检测systemctl 程序后台运行
Check_WireGuard() {
    ${1}_Status=$(systemctl is-active $1)
    ${1}_SelfStart=$(systemctl is-enabled $1 2>/dev/null)
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
# 检测是否为服务,返回0运行
check_enabled() {
    temp=$(systemctl is-enabled $1)
    if [[ x"${temp}" == x"enabled" ]]; then
        return 0
    else
        return 1
    fi
}
# 检查是否为root
#[[ $EUID -ne 0 ]] && red "错误：必须使用root用户运行此脚本！\n" && exit 1

# 显示系统info
Show_Information() {
    Get_Release
    Get_Ip
    blue "—————————————————————————————————————————————"
   
    echo -e "系统:$(blue "$release $lbit"位)  Arch：$(blue "$arch")  虚拟化：$(blue "$virt")"
    echo -e "IPV4:$(blue "$ipv4_address")"
    echo -e "IPV6:$(blue "$ipv6_address")"

    blue "—————————————————————————————————————————————"
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

# 卸载apache2
Uninstall_apache2() {
    Get_Cmd_Type
    
    if [[ $Cmd_Type == "apt" ]]; then
        #temp=$(dpkg -l | grep apache2)
        #if [ -n temp ]; then
            systemctl stop httpd.service
            apt-get --purge remove apache2 -y && apt-get --purge remove apache2-doc -y && apt-get --purge remove apache2-utils -y
            find /etc -name "*apache*" |xargs rm -rf && rm -rf /var/www && rm -rf /etc/libapache2-mod-jk
            yellow "卸载完成"
        #else yellow "无需卸载"
        #fi
    elif [[ $Cmd_Type == "yum" ]]; then
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

# 安装v2board面板
Install_V2board() {
    Get_Cmd_Type
    if [[ $Cmd_Type == "yum" ]]; then
        yum -y install git wget 
        git clone https://gitee.com/gz1903/v2board_install.git /usr/local/src/v2board_install 
        cd /usr/local/src/v2board_install && chmod +x v2board_install.sh && ./v2board_install.sh  
    else 
        red "仅支持centos系统！！！"
    fi
}
# vps常用脚本2级菜单
VPS_common_script() {
    clear
    echo -e "${yellow}vps常用脚本${plain}"
    echo -e ""
    echo -e "${yellow}1${plain}.warp"
    echo -e "${yellow}2${plain}.bbr"
    echo -e "${yellow}3${plain}.docker"
    echo -e "${yellow}4${plain}.钉钉内网穿透"
    echo -e "${yellow}5${plain}.Argo Tunnel内网穿透"
    echo -e "${yellow}6${plain}.路由回程测试"
    echo -e "${yellow}7${plain}.安装wireguard"
    echo -e "${yellow}8${plain}.安卓termux安装linux"
    echo -e ""
    echo -e "${yellow}0${plain}.返回主菜单"
    echo -e "${yellow}*${plain}.回车取消"
    echo -e ""
    read -p "请输入脚本序号:" VPS_common_script_Input
    
    case "$VPS_common_script_Input" in
        
        0) Main_Menu ;;
        1) wget -N https://raw.githubusercontent.com/fscarmen/warp/main/menu.sh && bash menu.sh ;;
        2) bash <(curl -Ls https://raw.githubusercontent.com/ppoonk/all/master/bbr-series.sh) ;;
        3) curl -fsSL https://get.docker.com | bash -s docker --mirror Aliyun ;;
        4) bash <(curl -Ls https://raw.githubusercontent.com/ppoonk/all/master/ding-tunnel.sh) ;;
        5) bash <(curl -Ls https://raw.githubusercontent.com/ppoonk/all/master/argo.sh) ;;
        6) wget https://raw.githubusercontent.com/nanqinlang-script/testrace/master/testrace.sh && bash testrace.sh ;;
        7) bash <(curl -Ls https://raw.githubusercontent.com/ppoonk/all/master/install-wireguard.sh) ;;
        8) bash <(curl -Ls https://raw.githubusercontent.com/ppoonk/all/master/install-termux-linux.sh) ;;
    esac
}
# linux一些命令2级菜单
Linux_commands() {
    clear
    echo -e "${yellow}linux一些命令${plain}"
    echo -e ""
    echo -e "${yellow}1${plain}.国内机更换github hosts"
    echo -e "${yellow}2${plain}.卸载apache2"
    echo -e "${yellow}3${plain}.写入systemctl服务"
    echo -e "${yellow}4${plain}.更新源"
    echo -e "${yellow}5${plain}.更新内核kernel"
    echo -e "${yellow}6${plain}.shc & unshc"
    echo -e "${yellow}7${plain}.linux开放所有端口"
    echo -e ""
    echo -e "${yellow}0${plain}.返回主菜单"
    echo -e "${yellow}*${plain}.回车取消"
    echo -e ""
    read -p "请输入脚本序号:" Linux_commands_Input
    
    case "$Linux_commands_Input" in
        
        0) Main_Menu ;;
        1) sed -i "/# GitHub520 Host Start/Q" /etc/hosts && curl https://raw.hellogithub.com/hosts >> /etc/hosts ;;
        2) Uninstall_apache2 ;;
        3) Add_Systemctl_Service ;;
        4) bash <(curl -Ls https://raw.githubusercontent.com/ppoonk/all/master/upgrade_sources.sh) ;;
        5) bash <(curl -Ls https://raw.githubusercontent.com/ppoonk/all/master/upgrade_kernel.sh) ;;
        6) bash <(curl -Ls https://raw.githubusercontent.com/ppoonk/all/master/shc-unshc.sh) ;;
        7) Open_ports ;;
    esac
}
# 机场2级菜单
Airport_menu() {
    clear
    echo -e "${yellow}机场相关脚本${plain}"
    echo -e ""
    echo -e "${yellow}1${plain}.v2board一键搭建（仅支持centos）"
    echo -e "${yellow}2${plain}.XrayR一键对接（前端创建好节点id，再执行此脚本）"
    echo -e "${yellow}3${plain}.mack-a八合一脚本"
    echo -e "${yellow}4${plain}.暂无"
    echo -e ""
    echo -e "${yellow}0${plain}.返回主菜单"
    echo -e "${yellow}*${plain}.回车取消"
    echo -e ""
    read -p "请输入脚本序号:" Airport_menu_Input
    
    case "$Airport_menu_Input" in
        
        0) Main_Menu ;;
        1) Install_V2board ;;
        2) bash <(curl -Ls https://raw.githubusercontent.com/ppoonk/all/master/xrayr/XrayR-new.sh) ;;
        3) bash <(curl -Ls https://raw.githubusercontent.com/mack-a/v2ray-agent/master/install.sh) ;;
    esac
}

# 面板2级菜单
Panel_menu() {
    clear
    echo -e "${yellow}面板相关脚本${plain}"
    echo -e ""
    echo -e "${yellow}1${plain}.宝塔面板 & mdserver-web面板"
    echo -e "${yellow}2${plain}.ddns-go面板"
    echo -e "${yellow}3${plain}.v2raya面板"
    echo -e "${yellow}4${plain}.ServerStatus-Hotaru探针"
    echo -e ""
    echo -e "${yellow}0${plain}.返回主菜单"
    echo -e "${yellow}*${plain}.回车取消"
    echo -e ""
    read -p "请输入脚本序号:" Panel_Input
    
    case "$Panel_Input" in
        
        0) Main_Menu ;;
        1) bash <(curl -Ls https://raw.githubusercontent.com/ppoonk/all/master/install-bt.sh) ;;
        2) bash <(curl -Ls https://raw.githubusercontent.com/ppoonk/all/master/install-ddns-go.sh) ;;
        3) bash <(curl -Ls https://raw.githubusercontent.com/ppoonk/all/master/install-v2raya.sh) ;;
        4) bash <(curl -Ls https://raw.githubusercontent.com/ppoonk/all/master/shc-unshc.sh) ;;
        5) wget https://raw.githubusercontent.com/cokemine/ServerStatus-Hotaru/master/status.sh 
        echo -e "        
        ServerStatus-Hotaru探针脚本下载完毕
        服务端：bash status.sh s
        客户端：bash status.sh c" ;;
        
    esac
}

# 主菜单
Main_Menu() {
    clear
    Show_Information
        #    echo -e "${yellow}10${plain}."
        #    echo -e ""

    echo -e "${yellow}1${plain}.bench跑分"
    echo -e "${yellow}2${plain}.vps三网测速"
    echo -e "${yellow}3${plain}.安装x-ui（支持linux与安卓deploy）"
    echo -e ""
    echo -e "${yellow}4${plain}.vps常用脚本（bbr、warp、docker、路由测试、内网穿透等）"
    echo -e "${yellow}5${plain}.linux一些命令"
    echo -e "${yellow}6${plain}.机场（v2board、XrayR、mack-a八合一等）"
    echo -e "${yellow}7${plain}.面板（ddns面板、v2raya面板、探针、宝塔等）"
    echo -e ""
    echo -e "${yellow}*${plain}.回车取消"
    echo -e ""
    read -p "请输入脚本序号:" Input
    
    case "$Input" in
        
        #1) bash <(curl -Ls https://raw.githubusercontent.com/ppoonk/all/master/bench.sh) ;;
	1) bash <(curl -Ls https://raw.githubusercontent.com/ppoonk/all/master/bench.sh) ;;
        2) bash <(curl -Lso- https://git.io/Jlkmw) ;;
        3) bash <(curl -Ls https://raw.githubusercontent.com/ppoonk/all/master/x-ui-series.sh) ;;
        4) VPS_common_script ;;
        5) Linux_commands ;;
        6) Airport_menu ;;
        7) Panel_menu ;;
    esac

}
Main_Menu
