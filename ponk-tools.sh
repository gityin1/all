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
    #返回0为运行
    if [[ count -ne 0 ]]; then
        return 0
    else
        return 1
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
    blue "—————————————————————————————————————————————"
   
    echo -e "系统:$(blue "$release $lbit"位)  Arch：$(blue "$arch")  虚拟化：$(blue "$virt")"   

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

# 安装宝塔
Install_BT() {
    yellow "
    1.安装宝塔770
    2.卸载宝塔
    3.安装mdserver-web
    4.卸载mdserver-web
    5.回车取消"
    read -p "请输入序号：" BT_input
    case $BT_input in
    1) wget -O install.sh http://download.bt.cn/install/install-ubuntu_6.0.sh && sudo bash install.sh
    wget http://download.bt.cn/install/update/LinuxPanel-7.7.0.zip && unzip LinuxPanel-7.7.0.zip
    cd /root/panel && bash update.sh
    mv /www/server/panel/data/bind.pl bind.pl1
    bt ;;
    2) /etc/init.d/bt stop && chkconfig --del bt && rm -f /etc/init.d/bt && rm -rf /www/server/panel ;;
    3) curl -fsSL  https://gitee.com/midoks/mdserver-web/raw/master/scripts/install_cn.sh | bash ;;
    4) /etc/init.d/mw stop && rm -rf /www/server/mdserver-web ;;
    5) exit 0;;
    esac
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
    echo -e "开始安装 x-ui "
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
#安卓deploy安装x-ui
Deploy_x-ui() {
    Download_deploy_x-ui() {

    if [[ -s /usr/local/x-ui.tar.gz ]]; then
        yellow "x-ui已下载"
    else
        yellow "正在从github下载，请耐心等待······"
        url="https://download.fastgit.org/vaxilu/x-ui/releases/latest/download/x-ui-linux-arm64.tar.gz"
        wget -N --no-check-certificate -O /usr/local/x-ui.tar.gz ${url}
    fi
    yellow "下载完成，正在解压"
    cd /usr/local/
    tar zxvf x-ui.tar.gz
    cd x-ui 
    chmod +x x-ui bin/xray-linux-arm64

    }
    Start_deploy_x-ui() {
        apt install screen -y
        cd /usr/local/x-ui
        screen -USdm x-ui ./x-ui
        yellow "x-ui已启动，访问IP:54321即可管理xui面板"
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
    yellow "
        1.安装x-ui
        2.卸载x-ui
        3.回车取消"
    read -p "选择序号：" deploy_xui_input
    case $deploy_xui_input in
        1) Download_deploy_x-ui && Start_deploy_x-ui ;;
        2) Uninstall_deploy_x-ui ;;
        3) exit 0 ;;
    esac

}

Deploy_ddns_go() {
    Download_deploy_ddns_go() {
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

    if [[ -s /usr/local/ddns.tar.gz ]]; then
        yellow "ddns-go已下载"
    else
        yellow "正在从github下载，请耐心等待······"
        wget -N --no-check-certificate -O /usr/local/ddns.tar.gz https://download.fastgit.org/jeessy2/ddns-go/releases/download/v3.7.0/ddns-go_3.7.0_Linux_${arch1}.tar.gz
    fi
    mkdir /usr/local/ddns-go
    tar zxvf ddns.tar.gz -C  /usr/local/ddns-go
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
        rm -rf /usr/local/ddns-go
        rm -rf /root/.ddns_go_config.yaml
        yellow "ddns-go卸载完成"

    }
    clear
    yellow "
        1.安装ddns-go
        2.卸载ddns-go
        3.回车取消"
    read -p "选择序号：" deploy_ddns_go_input
    case $deploy_ddns_go_input in
        1) Download_deploy_ddns_go && Start_deploy_ddns_go ;;
        2) Uninstall_deploy_ddns_go ;;
        3) exit 0 ;;
    esac

}

# 安装v2raya
V2raya() {
    Install_V2raya() {
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
        wget -N --no-check-certificate -O /root/xray.zip https://download.fastgit.org/XTLS/Xray-core/releases/download/v1.5.5/Xray-linux-${arch2}.zip
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
        wget -N --no-check-certificate -O /root/v2raya https://download.fastgit.org/v2rayA/v2rayA/releases/download/v1.5.7/v2raya_linux_${arch1}_1.5.7
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
        if [[ $? == 1 ]]; then
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
}


#安装DDNS-GO
DDNS_go() {
    Install_DDNS_go() {
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
        if [[ $? == 1 ]]; then
            yellow "
            ddns-go已在运行,访问ip:9876即可访问ddns-go面板
            使用方法 systemctl [start|restart|stop|status] ddns-go"
        else red "安装错误,重新运行脚本多尝试几次" && exit 1
    fi
    }

    Uninstall_DDNS_go() {
        yellow "正在卸载..."
        systemctl stop ddns-go
        rm -rf /etc/systemd/system/ddns-go.service
        rm -rf /usr/local/ddns-go
        rm -rf /root/.ddns_go_config.yaml
        yellow "ddns-go卸载完成"

    }
    clear
    yellow "
        1.安装ddns-go
        2.卸载ddns-go
        3.安卓deploy安装ddns
        4.回车取消"
    read -p "选择序号：" DDNS_go_input
    case $DDNS_go_input in
        1) Install_DDNS_go ;;
        2) Uninstall_DDNS_go ;;
        3) Deploy_ddns_go ;;
        4) exit 0 ;;
    esac

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
    #cd ~/Termux-Linux/Debian && ./start-debian.sh
}


# 钉钉内网穿透
Ding_Tunnel() {

    local type1=""
    if [[ $arch == "amd64" || $arch == "x64" || $arch == "x86_64" ]]; then
        type1="linux"
    elif [[ $arch == "arm64" || $arch == "aarch64" || $arch == "arm" || $arch == "armv7" || $arch == "armv6" || $arch == "armv6" || $arch == "armv7l"
]]; then
        type1="linux_arm"
    elif [[ $arch == "x86" ]]; then
        type1="linux_386"
    else red "不支持您的版本，或者手动去github库下载---https://github.com/open-dingtalk/dingtalk-pierced-client" 
    fi

    if [[ $Cmd_Type == "debian" ]]; then
       # apt update 
        apt install git screen -y
    elif [[ $Cmd_Type == "centos" ]]; then
       # yum update 
        yum install screen git -y
    else red "错误,本脚本仅适用于centos，ununtu和debian"
    fi


    Download_Ding_Tunnel() {

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
}


Install_shc() {
    local shc_status="未安装"

Install_shc1() {
    rm -f shc-3.8.9.tgz
    rm -rf /usr/local/man/man1
    rm -f /usr/local/bin/shc
    mkdir /usr/local/man/man1
    wget -N http://www.datsi.fi.upm.es/~frosal/sources/shc-3.8.9.tgz
    tar zxf shc-3.8.9.tgz 
    cd shc-3.8.9
    make
    make install
    yellow "安装完成"
    Show_shc_menu
}
Uninstall_shc1() {
    rm -f shc-3.8.9.tgz
    rm -rf /usr/local/man/man1
    rm -f /usr/local/bin/shc
    yellow "卸载完成"
}
Show_shc_menu() {

echo -e "
常用参数：
-e  date （指定过期日期）
-m  message （指定过期提示的信息） 
-f  script_name（指定要编译的shell的路径及文件名）
-r  Relax security. （可以相同操作系统的不同系统中执行）
-v  Verbose compilation（编译的详细情况）

使用方法：
# shc -v -f abc.sh
-f 后面跟需要加密的文件  ,运行后会生成两个文件: 
abc.sh.x     为二进制文件，赋予执行权限后，可直接执行
abc.sh.x.c   为c源文件。基本没用，可以删除

# 设定有效执行期限的方法，如：
# shc -e 28/01/2012 -m "过期了" -f abc.sh
选项“-e”指定过期时间，格式为“日/月/年”；选项“-m”指定过期后执行此shell程序的提示信息"
    

}
Check_shc_status() {
    [[ -s /usr/local/bin/shc ]] && shc_status="已安装"

}
Check_shc_status
    echo ""
    echo ""
    yellow "加密工具shc：$shc_status"
    yellow "1.安装shc   2.卸载shc  3.回车取消"
    read -p "输入序号：" Input_shc
    case $Input_shc in
    1) Install_shc1 ;;
    2) Uninstall_shc1 ;;
    *)  ;;
    esac

}
Unshc() {
    wget -c -N --no-check-certificate -O /root/UnSHc.sh https://raw.fastgit.org/ppoonk/all/master/UnSHc.sh && chmod +x UnSHc.sh && ./UnSHc.sh

}

BBR_series() {
    clear
    yellow "
    1.BBR
    2.BBr for openvz
    3.回车取消并退出"
    read -p "输入序号：" BBR_input
    case $BBR_input in
    1) wget -N --no-check-certificate "https://raw.githubusercontent.com/chiakge/Linux-NetSpeed/master/tcp.sh" 
    chmod +x tcp.sh && ./tcp.sh ;;
    2) wget --no-cache -O lkl-haproxy.sh https://github.com/mzz2017/lkl-haproxy/raw/master/lkl-haproxy.sh
    bash lkl-haproxy.sh ;;
    *) exit 0;;
    esac

}
XUI_series() {
    clear
    yellow "
    1.x-ui原版
    2.x-ui国内机适用
    3.安卓deploy安装x-ui
    4.回车取消并退出"
    read -p "输入序号：" XUI_input
    case $XUI_input in
    1) bash <(curl -Ls https://raw.githubusercontent.com/vaxilu/x-ui/master/install.sh) ;;
    2) Install_xui_cn ;;
    3) Deploy_x-ui ;;
    *) exit 0;;
    esac
}


# 菜单
Show_Menu() {
    clear
    clear
    Show_Information
   
    echo -e ""
    yellow "1.国内机更换github hosts"
    yellow "2.bench.sh"          
    yellow "3.三网测速 "           
    yellow "4.路由回程测试"             
    yellow "5.warp"
    echo -e ""

    yellow "6.安装x-ui"
    yellow "7.mack-a八合一脚本"
    yellow "8.BBR"
    yellow "9.下载XrayR"
    yellow "10.安装v2raya面板"
    echo -e ""

    yellow "11.安装DDNS-GO面板"
    yellow "12.卸载apache2"
    yellow "13.安卓termux安装linux"
    yellow "14.钉钉内网穿透"
    yellow "15.Argo Tunnel内网穿透"
    echo -e ""

    yellow "16.ServerStatus-Hotaru"
    yellow "17.shc加密script"
    yellow "18.unshc解密script"
    yellow "19.宝塔bt面板 & mdserver-web面板"
    yellow "20.写入systemctl服务"
    echo -e ""

    yellow "21.安装docker"
    yellow "22.安装v2board面板"
    echo -e ""

    yellow "0.回车或输入0退出"
    echo -e ""
    read -p "请输入脚本序号:" Input
    
    case "$Input" in
        0) exit 0 ;;
        1) sed -i "/# GitHub520 Host Start/Q" /etc/hosts && curl https://raw.hellogithub.com/hosts >> /etc/hosts ;;
        2) curl -so- 86.re/bench.sh | bash ;;
        3) bash <(curl -Lso- https://git.io/Jlkmw);;
        4) wget https://raw.githubusercontent.com/nanqinlang-script/testrace/master/testrace.sh && bash testrace.sh;;
        5) wget -N https://raw.githubusercontent.com/fscarmen/warp/main/menu.sh && bash menu.sh ;;

        6) XUI_series ;;
        7) wget -P /root -N --no-check-certificate "https://raw.githubusercontent.com/mack-a/v2ray-agent/master/install.sh" && chmod 700 /root/install.sh && /root/install.sh ;;
        8) BBR_series;;
        9) wget -O xrayr.zip https://github.com/Misaka-blog/XrayR/releases/latest/download/XrayR-linux-64.zip && unzip -d ./xrayr xrayr.zip ;;
        10) V2raya ;;

        11) DDNS_go ;;
        12) uninstall_apache2 ;;
        13) Install_Termux_Linux ;;
        14) Ding_Tunnel ;;
        15) wget -N https://raw.githubusercontents.com/Misaka-blog/argo-tunnel-script/master/argo.sh && bash argo.sh ;;

        16) wget https://raw.githubusercontent.com/cokemine/ServerStatus-Hotaru/master/status.sh 
        yellow "
        ServerStatus-Hotaru探针脚本下载完毕
        服务端：bash status.sh s
        客户端：bash status.sh c
        " ;;
        17) Install_shc ;;
        18) Unshc ;;
        19) Install_BT;;
        20) Add_Systemctl_Service ;;

        21) curl -fsSL https://get.docker.com | bash -s docker --mirror Aliyun ;;
        22) Install_V2board ;

       
        
    esac

}
# Add_Shell
Show_Menu
