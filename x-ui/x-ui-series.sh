#!/bin/bash

red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
plain='\033[0m'

# check root
[[ $EUID -ne 0 ]] && echo -e "${red}错误：${plain} 必须使用root用户运行此脚本！\n" && exit 1

#判断国内国外vps
v4=$(curl -s4m8 https://ip.gs -k)
#v6=$(curl -s6m8 https://ip.gs -k)
c4=$(curl -s4m8 https://ip.gs/country -k)
#c6=$(curl -s6m8 https://ip.gs/country -k)
install_type="cn"
if [[ $c4 != "China" ]]; then
    install_type="foreigner"
    
fi

status1="未安装"
status2="未运行"
    if [[ -f /etc/systemd/system/x-ui.service ]]; then
        status1="已安装"
    fi
    temp=$(systemctl status x-ui | grep Active | awk '{print $3}' | cut -d "(" -f2 | cut -d ")" -f1)
    if [[ x"${temp}" == x"running" ]]; then
        status2="已运行"
    fi
Install_xui_foreigner() {
    bash <(curl -Ls https://raw.githubusercontent.com/vaxilu/x-ui/master/install.sh)
}

#x-ui国内镜像
Install_xui_cn() {
    Get_Cmd_Type
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
    if [[ x"$Cmd_Type" == x"yum" ]]; then
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
#安装x-ui for deploy
Deploy_x-ui() {
    Download_deploy_x-ui() {

    # arm32位和arm64位下载地址
    [[ $lbit == 32 ]] && url="https://raw.fastgit.org/ppoonk/all/master/x-ui/x-ui-arm32.tar.gz"
    [[ $lbit == 64 ]] && url="https://download.fastgit.org/vaxilu/x-ui/releases/latest/download/x-ui-linux-arm64.tar.gz"
    if [[ -s /usr/local/x-ui.tar.gz ]]; then
        yellow "x-ui已下载"
    else
        yellow "正在从github下载，请耐心等待······"
        wget -N --no-check-certificate -O /usr/local/x-ui.tar.gz ${url}
    fi
    yellow "下载完成，正在解压"
    cd /usr/local/
    tar zxvf x-ui.tar.gz
    cd x-ui 
    chmod +x x-ui bin/*

    }
    Start_deploy_x-ui() {
        apt update -y
        apt install screen -y
        cd /usr/local/x-ui
        /usr/local/x-ui/x-ui setting -username admin -password admin
        screen -USdm x-ui ./x-ui
        #wget --no-check-certificate -O /usr/bin/x-ui https://raw.fastgit.org/vaxilu/x-ui/main/x-ui.sh
        #chmod +x /usr/bin/x-ui
        yellow "使用默认参数"
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
        2.启动x-ui
        3.停止x-ui
        4.卸载x-ui
        5.回车取消"
    read -p "选择序号：" deploy_xui_input
    case $deploy_xui_input in
        1) Download_deploy_x-ui && Start_deploy_x-ui ;;
        2) Start_deploy_x-ui ;;
        3) Stop_deploy_x-ui ;;
        4) Uninstall_deploy_x-ui ;;
        5) exit 0 ;;
    esac

    }

Xui_series_menu() {
    clear
    echo -e "
    vps IPv4：${green}$v4${plain}
    vps所在地：${green}$c4${plain}
    x-ui状态：${green}$status1  $status2${plain}
    1.Linux安装xui
    2.安卓deploy安装x-ui
    3.回车取消并退出"
    read -p "输入序号：" XUI_input
    case $XUI_input in
    1) Install_install_type ;;
    2) Deploy_x-ui ;;
    *) exit 0;;
    esac
    }
Xui_series_menu