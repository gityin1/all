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
        echo "error: 不支持您的架构"
        exit 1
        ;;
esac

TMP_DIRECTORY="$(mktemp -d)/"
XRAY_FILE="${TMP_DIRECTORY}Xray-linux-${MACHINE}.zip"
DOWNLOAD_XRAY_LINK="https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-${MACHINE}.zip"

install_software() {
    if [[ -n "$(command -v tar)" ]]; then
        return
    fi
    if [[ -n "$(command -v unzip)" ]]; then
        return
    fi
    if [ "$(command -v apk)" ]; then
        apk update
        apk add  unzip  tar
    else
        echo "error: 请手动安装apk curl unzip wget openssh tar"
        exit 1
    fi
}

install_xray() {
    wget -N --no-check-certificate -O ${XRAY_FILE} ${DOWNLOAD_XRAY_LINK}
    unzip -q ${XRAY_FILE} -d ${TMP_DIRECTORY}
    install -d /usr/local/xray/
    install -m 755 "${TMP_DIRECTORY}xray" "/usr/local/xray/xray"
    install -m 755 "${TMP_DIRECTORY}geoip.dat" "/usr/local/xray/geoip.dat"
    install -m 755 "${TMP_DIRECTORY}geosite.dat" "/usr/local/xray/geosite.dat"
    wget /usr/local/xray https://gitee.com/poiuty123/all/raw/master/x-ui/config.json

}

main() {
    install_software
    install_xray
    echo "默认vless，端口2052，配置文件请修改/usr/local/config.json"
}

main