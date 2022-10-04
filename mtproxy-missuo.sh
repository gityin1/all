#!/bin/bash
###
 # @Author: Vincent Young
 # @Date: 2022-07-01 15:29:23
 # @LastEditors: Vincent Young
 # @LastEditTime: 2022-07-30 19:26:45
 # @FilePath: /MTProxy/mtproxy.sh
 # @Telegram: https://t.me/missuo
 # 简单汉化。。。。。。
 # Copyright © 2022 by Vincent, All Rights Reserved. 
### 

PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

# Define Color
red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
plain='\033[0m'

# Make sure run with root
[[ $EUID -ne 0 ]] && echo -e "[${red}Error${plain}]Please run this script with ROOT!" && exit 1

download_file(){
	echo "检查系统..."

	bit=`uname -m`
	if [[ ${bit} = "x86_64" ]]; then
		bit="amd64"
    elif [[ ${bit} = "aarch64" ]]; then
        bit="arm64"
    else
	    bit="386"
    fi

    last_version=$(curl -Ls "https://api.github.com/repos/9seconds/mtg/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
    if [[ ! -n "$last_version" ]]; then
        echo -e "${red}检测mtg版本失败可能是由于超出了Github API限制，请稍后重试."
        exit 1
    fi
    echo -e "检测到最新版本的mtg: ${last_version}, 开始安装..."
    version=$(echo ${last_version} | sed 's/v//g')
    wget -N --no-check-certificate -O mtg-${version}-linux-${bit}.tar.gz https://github.com/9seconds/mtg/releases/download/${last_version}/mtg-${version}-linux-${bit}.tar.gz
    if [[ ! -f "mtg-${version}-linux-${bit}.tar.gz" ]]; then
        echo -e "${red}下载 mtg-${version}-linux-${bit}.tar.gz 失败, 请重试."
        exit 1
    fi
    tar -xzf mtg-${version}-linux-${bit}.tar.gz
    mv mtg-${version}-linux-${bit}/mtg /usr/bin/mtg
    rm -f mtg-${version}-linux-${bit}.tar.gz
    rm -rf mtg-${version}-linux-${bit}
    chmod +x /usr/bin/mtg
    echo -e "mtg-${version}-linux-${bit}.tar.gz 安装成功，开始配置..."
}

configure_mtg(){
    echo -e "配置mtg..."
    wget -N --no-check-certificate -O /etc/mtg.toml https://raw.githubusercontent.com/missuo/MTProxy/main/mtg.toml
    
    echo ""
    read -p "请输入一个假域名（默认为itunes.apple.com）: " domain
	[ -z "${domain}" ] && domain="itunes.apple.com"

	echo ""
    read -p "输入要侦听的端口（默认为8443）:" port
	[ -z "${port}" ] && port="8443"

    secret=$(mtg generate-secret --hex $domain)
    
    echo "等待配置..."

    sed -i "s/secret.*/secret = \"${secret}\"/g" /etc/mtg.toml
    sed -i "s/bind-to.*/bind-to = \"0.0.0.0:${port}\"/g" /etc/mtg.toml

    echo "mtg配置成功，开始配置systemctl..."
}

configure_systemctl(){
    echo -e "配置systemctl..."
    wget -N --no-check-certificate -O /etc/systemd/system/mtg.service https://raw.githubusercontent.com/missuo/MTProxy/main/mtg.service
    systemctl enable mtg
    systemctl start mtg
    echo "mtg配置成功，开始配置防火墙..."
    systemctl disable firewalld
    systemctl stop firewalld
    ufw disable
    echo "mtg启动成功，享受它!"
    echo ""
    # echo "mtg configuration:"
    # mtg_config=$(mtg access /etc/mtg.toml)
    public_ip=$(curl -s ipv4.ip.sb)
    subscription_config="tg://proxy?server=${public_ip}&port=${port}&secret=${secret}"
    subscription_link="https://t.me/proxy?server=${public_ip}&port=${port}&secret=${secret}"
    echo -e "${subscription_config}"
    echo -e "${subscription_link}"
}

change_port(){
    read -p "输入要修改的端口（默认8443）:" port
	[ -z "${port}" ] && port="8443"
    sed -i "s/bind-to.*/bind-to = \"0.0.0.0:${port}\"/g" /etc/mtg.toml
    echo "重启MT代理..."
    systemctl restart mtg
    echo "MTProxy已成功重新启动!"
}

change_secret(){
    echo -e "请注意，未经授权修改Secret可能会导致MTProxy无法正常运行."
    read -p "输入要修改的密码:" secret
	[ -z "${secret}" ] && secret="$(mtg generate-secret --hex itunes.apple.com)"
    sed -i "s/secret.*/secret = \"${secret}\"/g" /etc/mtg.toml
    echo "密钥更改成功!"
    echo "重启MT代理..."
    systemctl restart mtg
    echo "MTProxy已成功重新启动!"
}

update_mtg(){
    echo -e "更新mtg..."
    download_file
    echo "mtg更新成功，开始重新启动MTProxy..."
    systemctl restart mtg
    echo "MTProxy已成功重新启动!"
}

start_menu() {
    clear
    echo -e "  MTProxy v2一键式安装
---- by Vincent | github.com/missuo/MTProxy ----
 ${green} 1.${plain} 安装MTProxy
 ${green} 2.${plain} 安装MTProxy
————————————
 ${green} 3.${plain} 启动 MTProxy
 ${green} 4.${plain} 停止 MTProxy
 ${green} 5.${plain} 重启 MTProxy
 ${green} 6.${plain} 更改侦听端口
 ${green} 7.${plain} 更改密码
 ${green} 8.${plain} Update MTProxy
————————————
 ${green} 0.${plain} Exit
————————————" && echo

	read -e -p " 请输入数字 [0-5]: " num
	case "$num" in
    1)
		download_file
        configure_mtg
        configure_systemctl
		;;
    2)
        echo "Uninstall MTProxy..."
        systemctl stop mtg
        systemctl disable mtg
        rm -rf /usr/bin/mtg
        rm -rf /etc/mtg.toml
        rm -rf /etc/systemd/system/mtg.service
        echo "Uninstall MTProxy successfully!"
        ;;
    3) 
        echo "Starting MTProxy..."
        systemctl start mtg
        systemctl enable mtg
        echo "MTProxy started successfully!"
        ;;
    4) 
        echo "Stopping MTProxy..."
        systemctl stop mtg
        systemctl disable mtg
        echo "MTProxy stopped successfully!"
        ;;
    5)  
        echo "Restarting MTProxy..."
        systemctl restart mtg
        echo "MTProxy restarted successfully!"
        ;;
    6) 
        change_port
        ;;
    7)
        change_secret
        ;;
    8)
        update_mtg
        ;;
    0) exit 0
        ;;
    *) echo -e "${Error} 请输入数字 [0-5]: "
        ;;
    esac
}
start_menu