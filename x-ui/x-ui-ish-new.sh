#!/usr/bin/env bash

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
        echo "error: 请手动安装unzip tar"
        exit 1
    fi
}


install_xui() {
    
    rm /usr/local/x-ui/ -rf
    
    wget -N --no-check-certificate -O /usr/local/x-ui-linux-amd64.tar.gz "${DOWNLOAD_XUI_LINK}"
    cd /usr/local/
    tar zxvf x-ui-linux-amd64.tar.gz
    rm x-ui-linux-amd64.tar.gz -f
    cd x-ui
    chmod +x x-ui x-ui.sh 
  
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