
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
plain='\033[0m'

#获取release第二种方法
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
#更新sources源，Ubuntu、debian 

    Get_Release
    Upgrade_Sources_debian() {
        sources_bak_path=$(date +"%d-%m-%Y")
        mv /etc/apt/sources.list /etc/apt/sources.list.${sources_bak_path}
        yellow "
        旧文件已备份为：/etc/apt/sources.list.${sources_bak_path}
        正在更新源..."
        echo -e "
        deb http://mirrors.ustc.edu.cn/debian stable main contrib non-free
        # deb-src http://mirrors.ustc.edu.cn/debian stable main contrib non-free
        deb http://mirrors.ustc.edu.cn/debian stable-updates main contrib non-free
        # deb-src http://mirrors.ustc.edu.cn/debian stable-updates main contrib non-free
        # deb http://mirrors.ustc.edu.cn/debian stable-proposed-updates main contrib non-free
        # deb-src http://mirrors.ustc.edu.cn/debian stable-proposed-updates main contrib non-free" > /etc/apt/sources.list

        #更新，是索引生效
        sudo apt-get update
        yellow "已更新国内中科大USTC源"
        }
    Upgrade_Sources_ubuntu() {
        sources_bak_path=$(date +"%d-%m-%Y")
        mv /etc/apt/sources.list /etc/apt/sources.list.${sources_bak_path}
        yellow "
        旧文件已备份为：/etc/apt/sources.list.${sources_bak_path}
        正在更新源..."
        echo -e "
        # 默认注释了源码仓库，如有需要可自行取消注释
        deb https://mirrors.ustc.edu.cn/ubuntu/ focal main restricted universe multiverse
        # deb-src https://mirrors.ustc.edu.cn/ubuntu/ focal main restricted universe multiverse
        deb https://mirrors.ustc.edu.cn/ubuntu/ focal-security main restricted universe multiverse
        # deb-src https://mirrors.ustc.edu.cn/ubuntu/ focal-security main restricted universe multiverse
        deb https://mirrors.ustc.edu.cn/ubuntu/ focal-updates main restricted universe multiverse
        # deb-src https://mirrors.ustc.edu.cn/ubuntu/ focal-updates main restricted universe multiverse
        deb https://mirrors.ustc.edu.cn/ubuntu/ focal-backports main restricted universe multiverse
        # deb-src https://mirrors.ustc.edu.cn/ubuntu/ focal-backports main restricted universe multiverse" > /etc/apt/sources.list
        #更新，是索引生效
        sudo apt-get update
        yellow "已更新国内中科大USTC源"

    }

    case $release in
    debian) upgrade_sources_type="debian" ;;
    ubuntu) upgrade_sources_type="ubuntu" ;;
    *) red "仅支持debian、ubuntu，其他系统请手动" && exit 1 ;;
    esac
    clear
    echo -e "
    您的系统为：$(blue "$upgrade_sources_type $lbit 位")
    1.更新国内中科大USTC源
    2.回车退出
    "
    read -p "是否更新？请输入序号：" upgrade_sources_input
    case $upgrade_sources_input in
    1) Upgrade_Sources_${upgrade_sources_type} ;;
    *) exit 0 ;;
    esac


