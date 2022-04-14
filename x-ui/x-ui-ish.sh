#!/usr/bin/env bash

#set -euxo pipefail

# Identify architecture
case "$(arch -s)" in
    'i386' | 'i686')
        MACHINE='32'
        ;;
    'amd64' | 'x86_64')
        MACHINE='64'
        ;;
    'armv5tel')
        MACHINE='arm32-v5'
        ;;
    'armv6l')
        MACHINE='arm32-v6'
        grep Features /proc/cpuinfo | grep -qw 'vfp' || MACHINE='arm32-v5'
        ;;
    'armv7' | 'armv7l')
        MACHINE='arm32-v7a'
        grep Features /proc/cpuinfo | grep -qw 'vfp' || MACHINE='arm32-v5'
        ;;
    'armv8' | 'aarch64')
        MACHINE='arm64-v8a'
        ;;
    'mips')
        MACHINE='mips32'
        ;;
    'mipsle')
        MACHINE='mips32le'
        ;;
    'mips64')
        MACHINE='mips64'
        ;;
    'mips64le')
        MACHINE='mips64le'
        ;;
    'ppc64')
        MACHINE='ppc64'
        ;;
    'ppc64le')
        MACHINE='ppc64le'
        ;;
    'riscv64')
        MACHINE='riscv64'
        ;;
    's390x')
        MACHINE='s390x'
        ;;
    *)
        echo "error: 不支持的架构"
        exit 1
        ;;
esac

TMP_DIRECTORY="$(mktemp -d)/"
XRAY_FILE="${TMP_DIRECTORY}Xray-linux-$MACHINE.zip"
DOWNLOAD_XRAY_LINK="https://download.fastgit.org/XTLS/Xray-core/releases/latest/download/Xray-linux-$MACHINE.zip"

install_software() {
   
        apk add wget unzip openrc -y

}

install_xray() {
    wget -N --no-check-certificate -O ${XRAY_FILE} ${DOWNLOAD_XRAY_LINK}
    unzip -q ${XRAY_FILE} -d ${TMP_DIRECTORY}
    install -d /usr/local/xray/
    install -m 755 "${TMP_DIRECTORY}xray" "/usr/local/xray/xray"
    install -m 755 "${TMP_DIRECTORY}geoip.dat" "/usr/local/xray/geoip.dat"
    install -m 755 "${TMP_DIRECTORY}geosite.dat" "/usr/local/xray/geosite.dat"
    wget -O /usr/local/xray/config.json https://raw.fastgit.org/ppoonk/all/master/x-ui/config.json
    chmod +x /usr/local/xray/config.json
    OPENRC='0'
    wget -O /etc/init.d/xray https://raw.fastgit.org/ppoonk/all/master/x-ui/xray-init
    OPENRC='1'
    
}

main() {
    
     if [ -n "$(pgrep xray)" ]; then
        echo -e "xray已经运行" 
     else
        echo -e "开始安装"
        install_software
        install_xray
        rc-service xray start
        if [ -n "$(pgrep xray)" ]; then
            echo -e "xray已经运行"
            echo -e "启动xray：rc-service xray start"
            echo -e "重启xray：rc-service xray restart"
            echo -e "停止xray：rc-service xray stop"
            echo -e "查看xray状态：rc-service xray status"
            echo -e "默认vless，协议：ws，端口：2052，uuid：674d273d-3211-4fd1-9de2-89f6846a0688"
            echo -e "配置文件请修改/usr/local/config.json"
            echo -e "修改完毕请重启xray"
            else echo -e "安装失败，请参考xray官方仓库手动安装"
        fi
    fi
}
main