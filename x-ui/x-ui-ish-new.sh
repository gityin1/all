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
ZIP_FILE="${TMP_DIRECTORY}Xray-linux-$MACHINE.zip"
DOWNLOAD_LINK="https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-$MACHINE.zip"

install_software() {
    if [[ -n "$(command -v wget)" ]]; then
        return
    fi
    if [[ -n "$(command -v unzip)" ]]; then
        return
    fi
    if [ "$(command -v apk)" ]; then
        apk add wget unzip -y
    else
        echo "error: 请手动安装."
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
    chmod +x /usr/local/xray/config.json
    OPENRC='0'
    wget /etc/init.d/xray https://gitee.com/poiuty123/all/raw/master/x-ui/init.d
    OPENRC='1'
    
}

is_it_running() {
    XRAY_RUNNING='0'
    if [ -n "$(pgrep xray)" ]; then
        rc-service xray stop
        XRAY_RUNNING='1'
    fi
}


main() {
    install_software
    is_it_running
    install_xray
}

main