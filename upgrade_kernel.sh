
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


# 升级kernel，debian、ubuntu

    Get_Release
    current_kernel=$(uname -r)
    Upgrade_kernel_debian() {
        Upgrade_kernel_debian
        sudo apt-get update && sudo apt-get dist-upgrade -y
        apt -t bullseye-backports install linux-image-amd64 -y
        apt -t bullseye-backports install linux-headers-amd64 -y
        #更新引导
        update-grub
        yellow "kernel更新完成，请重启服务器生效"

    }
    Upgrade_kernel_ubuntu() {
        #查看当前系统内核
        # dpkg --get-selections| grep linux1
        #卸载多余内核
        # sudo apt-get remove --purge linux-image-4.2.0-22-generic123
        # sudo apt-get autoclean
        # sudo apt-get autoremove12
        yellow "正在下载..."
        url_header="https://kernel.ubuntu.com/~kernel-ppa/mainline/v5.19-rc7/amd64/linux-headers-5.19.0-051900rc7-generic_5.19.0-051900rc7.202207172131_amd64.deb"
        url_herder_all="https://kernel.ubuntu.com/~kernel-ppa/mainline/v5.19-rc7/amd64/linux-headers-5.19.0-051900rc7_5.19.0-051900rc7.202207172131_all.deb"
        url_image="https://kernel.ubuntu.com/~kernel-ppa/mainline/v5.19-rc7/amd64/linux-image-unsigned-5.19.0-051900rc7-generic_5.19.0-051900rc7.202207172131_amd64.deb"
        url_modules="https://kernel.ubuntu.com/~kernel-ppa/mainline/v5.19-rc7/amd64/linux-modules-5.19.0-051900rc7-generic_5.19.0-051900rc7.202207172131_amd64.deb"
        mkdir /root/temp_kernel
        wget -N --no-check-certificate -O /root/temp_kernel/header.deb $url_header
        wget -N --no-check-certificate -O /root/temp_kernel/herder_all.deb $url_herder_all
        wget -N --no-check-certificate -O /root/temp_kernel/image.deb $url_header
        wget -N --no-check-certificate -O /root/temp_kernel/modules.deb $url_header
        cd /root/temp_kernel
        yellow "正在安装..."
        sudo dpkg -i header.deb
        sudo dpkg -i herder_all.deb 
        sudo dpkg -i image.deb
        sudo dpkg -i modules.deb
        #更新引导
        yellow "正在更新引导..."
        update-grub
        yellow "kernel更新完成，请重启服务器生效"
    }

    case $release in
    debian) upgrade_kernel_type="debian";;
    ubuntu) upgrade_kernel_type="ubuntu" ;;

    *) red "仅支持debian、ubuntu" && exit 1 ;;
    esac
    echo -e "
    您的系统为：$(blue "$upgrade_kernel_type")
    当前内核为：$(blue "$current_kernel")
    1.三思之后确认升级内核kernel
    2.回车退出
    "
    read -p "升级内核有未知风险，是否升级内核？请输入序号：" upgrade_kernel_input
    case $upgrade_kernel_input in
    1) Upgrade_kernel_${upgrade_kernel_type} ;;
    2) exit 0 ;;
    esac
