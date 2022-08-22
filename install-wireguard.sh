#!/bin/bash

#安装wireguard，手动配置
Wireguard() {
    # 在KVM的前提下，判断 Linux 版本是否小于 5.6，如是则安装 wireguard 内核模块，变量 WG=1。由于 linux 不能直接用小数作比较，所以用 （主版本号 * 100 + 次版本号 ）与 506 作比较
    [[ $(($(uname -r | cut -d . -f1) * 100 +  $(uname -r | cut -d . -f2))) -lt 506 ]] && WG=1
    Wireguard_debian(){
            # 添加 backports 源,之后才能安装 wireguard-tools 
            echo "deb http://deb.debian.org/debian/ unstable main" > /etc/apt/sources.list.d/unstable-wireguard.list
            echo -e "Package: *\nPin: release a=unstable\nPin-Priority: 150\n" > /etc/apt/preferences.d/limit-unstable
            # 更新源
            #更新源并安装
            apt-get update
            apt-get install  wireguard-tools net-tools iproute2 openresolv dnsutils iptables
            # 如 Linux 版本低于5.6并且是 kvm，则安装 wireguard 内核模块
            [[ $WG = 1 ]] && apt install --no-install-recommends linux-headers-"$(uname -r)" && apt install --no-install-recommends wireguard-dkms
            }

    Wireguard_ubuntu(){
            # 更新源
            apt update -y
            # 安装一些必要的网络工具包和 wireguard-tools (Wire-Guard 配置工具：wg、wg-quick)
            #报错修复
            apt --fix-broken install -y
            apt install -y --no-install-recommends net-tools iproute2 openresolv dnsutils iptables
            apt install -y --no-install-recommends wireguard-tools

            #Ubuntu添加库
            #add-apt-repository ppa:wireguard/wireguard
            #更新源并安装
            #apt-get update
            #apt-get install wireguard
            }
            
    Wireguard_centOS(){
            # 安装一些必要的网络工具包和wireguard-tools (Wire-Guard 配置工具：wg、wg-quick)
            yum install -y epel-release elrepo-release yum-plugin-elrepo
            yum install -y net-tools iptables
            yum install -y wireguard-tools

            # 如 Linux 版本低于5.6并且是 kvm，则安装 wireguard 内核模块
            VERSION_ID="7"
            [[ $WG = 1 ]] && curl -Lo /etc/yum.repos.d/wireguard.repo https://copr.fedorainfracloud.org/coprs/jdoss/wireguard/repo/epel-"$VERSION_ID"/jdoss-wireguard-epel-"$VERSION_ID".repo && yum install -y wireguard-dkms
            # 升级所有包同时也升级软件和系统内核
            yum update -y
        }

    WireGuard_Interface='wgcf'

    #安装wg
    Install_WireGuardTools() {
        Get_Release
        current_kernel=$(uname -r)
        echo -e "
        您的系统为：$(blue "$release")
        当前内核为：$(blue "$current_kernel")
        1.确认安装wireguard
        2.回车退出
        "
        read -p "请输入序号：" install_wireguard_input
        case $install_wireguard_input in
        1) Wireguard_${release} ;;
        2) exit 0 ;;
        esac


    }
    Install_WireGuard() {
        
        Check_WireGuard
        if [[ ${WireGuard_SelfStart} != enabled || ${WireGuard_Status} != active ]]; then
            Install_WireGuardTools
        else
            yellow "WireGuard 正在运行"
        fi
    }
    #检查wg
    Check_WireGuard() {
        WireGuard_Status=$(systemctl is-active wg-quick@wgcf)
        WireGuard_SelfStart=$(systemctl is-enabled wg-quick@wgcf 2>/dev/null)
    }
    #启动wg
    Start_WireGuard() {
        yellow "正在启动wg..."
        # 设置开机自启
        systemctl enable wg-quick@wgcf --now
        # 启用守护进程
        systemctl start wg-quick@wgcf
        Check_WireGuard
        WireGuard_change_dns
        if [[ ${WireGuard_Status} = active ]]; then
            yellow "WireGuard已运行."
        else
            red "WireGuard 运行失败"

            exit 1
        fi
    }
    #停止wg
    Stop_WireGuard() {

            systemctl stop wg-quick@wgcf
            Check_WireGuard
            if [[ ${WireGuard_Status} != active ]]; then
                yellow "WireGuard 已停止."
            else
                red "WireGuard 停止失败"
            fi
    }
    #卸载wg
    Uninstall_WireGuard() {
        #wg-quick down wgcf
        systemctl stop wg-quick@wgcf
        #systemctl disable wg-quick@wgcf
        systemctl disable --now wg-quick@wgcf

    }
    #修改dns
    WireGuard_change_dns() {
        
        WireGuard_change_dns_path=$(date +"%M-%k-%m-%Y")
        mv /etc/resolv.conf /etc/resolv.conf.${WireGuard_change_dns_path}
        yellow "原dns备份到：/etc/resolv.conf.${WireGuard_change_dns_path}"
        echo -e "nameserver 2001:4860:4860::8844
            nameserver 114.114.114.114
            nameserver 8.8.8.8" > /etc/resolv.conf
        yellow "dns修改完成"
  
    }
    Wireguard_menu() {
        echo -e "
        配置文件路径：$(yellow "/etc/wireguard/wgcf.conf")
        请手动修改配置文件！！！！！！！！！！！
        1.安装wg
        2.启动wg
        3.停止wg
        4.关闭wg
        "
        read -p "输入序号：" Input
        case $Input in
        1) Install_WireGuard ;;
        2) Start_WireGuard ;;
        3) Stop_WireGuard ;;
        4) Uninstall_WireGuard;;
        5) exit 0 ;;
        esac
    }
    Wireguard_menu
    }