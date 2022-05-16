#!/bin/bash

# 控制台字体
green() {
	echo -e "\033[32m\033[01m$1\033[0m"
}

red() {
	echo -e "\033[31m\033[01m$1\033[0m"
}

yellow() {
	echo -e "\033[33m\033[01m$1\033[0m"
}
# arch
arch=$(uname -m)
# release

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
    red "未检测到系统版本\n"
    release="未知"
fi

install_base() {
    if [[ x"${release}" == x"centos" ]]; then
        yum install wget curl tar -y
    elif [[ x"${release}" == x"debian" ]]; then
        apt install wget curl tar -y
    else
        red "非centos，debain系统！！！"
    fi
}


# check root
[[ $EUID -ne 0 ]] && echo -e red "错误：必须使用root用户运行此脚本！\n" && exit 1

# 返回主菜单
Before_Show_Menu() {
    yellow "按回车返回主菜单: " && read temp
    Show_Menu
}
# 菜单
Show_Menu() {
    clear
    green "---------------------------"
    yellow "请输入需要执行的脚本序号"
    green "---------------------------"
    yellow "11.国内机更换github hosts——更新至2022-5-15"
    yellow "12.bench.sh"
    yellow "13.三网测速"
    yellow "14.路由回程测试"
    yellow "15.warp"
    greeen "----------------------------"
    yellow "21.x-ui"
    yellow "22.mack-a八合一脚本"
    yellow "23.CloudFlare Argo Tunnel隧道"
    yellow "24.BBR"
    yellow "25.BBr for openvz"
    yellow "26.下载XrayR"
    greeen "----------------------------"
    yellow "31.ServerStatus-Hotaru服务端"
    yellow "32.ServerStatus-Hotaru客户端"
    greeen "----------------------------"
    yellow "41.安装宝塔770"
    yellow "43.将xxx写入systemctl服务"

    yellow "0.回车或输入0退出"
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
        43) Add_Systemctl_Service ;;
        
    esac

}
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
BT() {
    wget -O install.sh http://download.bt.cn/install/install-ubuntu_6.0.sh && sudo bash install.sh
    wget http://download.bt.cn/install/update/LinuxPanel-7.7.0.zip && unzip LinuxPanel-7.7.0.zip
    cd /root/panel && bash update.sh
    mv /www/server/panel/data/bind.pl bind.pl1
    bt
    #Before_Show_Menu

}
Show_Menu