#!/usr/bin/env bash

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
    
    *)
        echo "error:不支持您的架构"
        exit 1
        ;;
esac

TMP_DIRECTORY="$(mktemp -d)/"
XRAY_FILE="${TMP_DIRECTORY}Xray-linux-${MACHINE}.zip"
DOWNLOAD_XRAY_LINK="https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-${MACHINE}.zip"

install_software() {
        apk update
        apk add unzip tar openrc wget

install_xray() {
    wget -N --no-check-certificate -O ${XRAY_FILE} ${DOWNLOAD_XRAY_LINK}
    unzip -q ${XRAY_FILE} -d ${TMP_DIRECTORY}
    install -d /usr/local/xray/
    install -m 755 "${TMP_DIRECTORY}xray" "/usr/local/xray/xray"
    install -m 755 "${TMP_DIRECTORY}geoip.dat" "/usr/local/xray/geoip.dat"
    install -m 755 "${TMP_DIRECTORY}geosite.dat" "/usr/local/xray/geosite.dat"
    wget /usr/local/xray https://gitee.com/poiuty123/all/raw/master/x-ui/config.json
    chmod +x /usr/local/xray/config.json

}

main() {
    install_software
    install_xray
    echo -e "默认vless，端口2052，配置文件请修改/usr/local/config.json"
}
echo -e "开始安装"
main