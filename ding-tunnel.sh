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
Get_Cmd_Type() {
        if [[ $(command -v apt-get) ]]; then
    Cmd_Type="apt"
    elif [[ $(command -v yum) ]]; then
        Cmd_Type="yum"
    else red "只支持debian与centos"
    fi
}
Set_directory_type() {
        local type1=""
    if [[ $arch == "amd64" || $arch == "x64" || $arch == "x86_64" ]]; then
        type1="linux"
    elif [[ $arch == "arm64" || $arch == "aarch64" || $arch == "arm" ]]; then
        type1="linux_arm"
    elif [[ $arch == "armv7" || $arch == "armv6" || $arch == "armv6" || $arch == "armv7l" ]]; then
        type1="linux_arm"
    elif [[ $arch == "x86" ]]; then
        type1="linux_386"
    else red "不支持您的版本，或者手动去github库下载---https://github.com/open-dingtalk/dingtalk-pierced-client" 
    fi
}

Install_base() {
        Get_Cmd_Type
        if [[ $Cmd_Type == "apt" ]]; then
       # apt update 
        apt install git screen -y
    elif [[ $Cmd_Type == "yum" ]]; then
       # yum update 
        yum install screen git -y
    else red "错误,本脚本仅适用于centos，ununtu和debian"
    fi
}

Download_Ding_Tunnel() {
    Get_Release
    Get_Cmd_Type
    Set_directory_type

        #git clone https://github.com/open-dingtalk/dingtalk-pierced-client.git 
        git clone  https://hub.fastgit.xyz/open-dingtalk/dingtalk-pierced-client.git /root/ding_tunnel
        echo && echo -n -e "下载完成，按回车返回主菜单: " && read temp
        Show_Ding_Menu
    }


Uninstall_Ding_Tunnel() {
        rm -rf /root/ding_tunnel
        yellow "钉钉内网穿透已卸载"
    }


local ding_status=""
Check_Ding_Tunnel() {
        if  [ -d /root/ding_tunnel ]; then
            ding_status="已下载"
        else ding_status="未下载"
        fi
    }

Show_Ding_Tunnel() {
        
        echo -e "钉钉已存在隧道："
        yellow "$(screen -ls | grep ding)"
        echo && echo -n -e "按回车返回主菜单: " && read temp
        Show_Ding_Menu
    }
Add_Ding_Tunnal() {
        if [[ $ding_status == "已下载" ]]; then
        cd /root/ding_tunnel/$type1
        chmod 777 ./ding
        read -p "请输入域名前缀，该前缀将会匹配到“vaiwan.cn”前面，例如你输入的是abc，启动工具后会将abc.vaiwan.cn映射到本地:"  Input_Sub
        read -p "请输入需要映射的端口:"  Input_Port
        screen -USdm ding${Input_Sub} ./ding -config=./ding.cfg -subdomain=$Input_Sub $Input_Port
        yellow "访问地址：${Input_Sub}.vaiwan.cn 端口为：$Input_Port"
        echo && yellow "按回车返回主菜单: " && read temp
        Show_Ding_Menu
        else red "请先安装钉钉内网穿透"
        echo && yellow "按回车返回主菜单: " && read temp
        Show_Ding_Menu
        fi
    }
Delete_Ding_Tunnel() {
        echo -e "钉钉已存在隧道："
        yellow "$(screen -ls | grep ding)"
        read -p "输入需要删除的隧道：" Del_Ding_Tunnel_Name
        screen -S $Del_Ding_Tunnel_Name -X quit

        echo && echo -n -e "$(yellow "$Del_Ding_Tunnel_Name")已被删除，按回车返回主菜单: " && read temp
        Show_Ding_Menu

    }
Show_Ding_Menu() {
	clear 
    Check_Ding_Tunnel
	echo -e "钉钉内网穿透：$(yellow "$ding_status")"
	echo -e "钉钉隧道列表：$(yellow "$(screen -ls | grep ding)")"
	echo "            "
	echo "1. 下载钉钉内网穿透"
    echo "2. 新增钉钉隧道"
    echo "3. 删除钉钉隧道"
	#echo "4. 显示钉钉隧道列表"
	echo "4. 卸载钉钉内网穿透"
	echo "0. 退出"
	echo "          "
	read -p "请输入选项:" Input
	case "$Input" in
		1) Download_Ding_Tunnel ;;
		2) Add_Ding_Tunnal ;;
        3) Delete_Ding_Tunnel ;;
		#4) Show_Ding_Tunnel ;;
		4) Uninstall_Ding_Tunnel ;;
		*) exit 1 ;;
	esac
    }
Show_Ding_Menu
