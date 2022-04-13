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
        echo "error: 不支持您的架构"
        exit 1
        ;;
esac

TMP_DIRECTORY="$(mktemp -d)/"
XRAY_FILE="${TMP_DIRECTORY}Xray-linux-${MACHINE}.zip"
DOWNLOAD_XRAY_LINK="https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-${MACHINE}.zip"
DOWNLOAD_XUI_LINK="https://github.com/vaxilu/x-ui/releases/latest/download/x-ui-linux-amd64.tar.gz"

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


install_xui() {
    if [[ -e /usr/local/x-ui/ ]]; then
        rm /usr/local/x-ui/ -rf
    fi
    wget -N --no-check-certificate -O /usr/local/x-ui-linux-amd64.tar.gz "${DOWNLOAD_XUI_LINK}"
    tar zxvf x-ui-linux-amd64.tar.gz
    rm x-ui-linux-amd64.tar.gz -f
    cd x-ui
    chmod +x x-ui x-ui.sh
    cp -f x-ui.service /etc/systemd/system/
    #wget --no-check-certificate -O /usr/bin/x-ui https://raw.githubusercontent.com/vaxilu/x-ui/main/x-ui.sh
    chmod +x /usr/bin/x-ui
    systemctl enable x-ui
    systemctl start x-ui
}

install_xray() {
    wget -N --no-check-certificate -O ${XRAY_FILE} ${DOWNLOAD_XRAY_LINK}
    unzip -q ${XRAY_FILE} -d ${TMP_DIRECTORY}
    rm -rf /usr/local/bin/${XRAY_FILE}
    install -m 755 "${TMP_DIRECTORY}xray" "/usr/local/bin/xray-linux-amd64"
 
}

main() {
    install_software
    install_xui
    install_xray
}

main