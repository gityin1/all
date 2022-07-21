#!/bin/bash



red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
plain='\033[0m'

cur_dir=$(pwd)

# check root
[[ $EUID -ne 0 ]] && echo -e "${red}错误：${plain} 必须使用root用户运行此脚本！\n" && exit 1

# check os
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
    echo -e "${red}未检测到系统版本，请联系脚本作者！${plain}\n" && exit 1
fi
#本软件不支持 32 位系统(x86)，请使用 64 位系统(x86_64)
if [ "$(getconf WORD_BIT)" != '32' ] && [ "$(getconf LONG_BIT)" != '64' ] ; then
    echo "本软件不支持 32 位系统(x86)，请使用 64 位系统(x86_64)，如果检测有误，请联系作者"
    exit 2
fi

os_version=""

# os version
if [[ -f /etc/os-release ]]; then
    os_version=$(awk -F'[= ."]' '/VERSION_ID/{print $3}' /etc/os-release)
fi
if [[ -z "$os_version" && -f /etc/lsb-release ]]; then
    os_version=$(awk -F'[= ."]+' '/DISTRIB_RELEASE/{print $2}' /etc/lsb-release)
fi

if [[ x"${release}" == x"centos" ]]; then
    if [[ ${os_version} -le 6 ]]; then
        echo -e "${red}请使用 CentOS 7 或更高版本的系统！${plain}\n" && exit 1
    fi
elif [[ x"${release}" == x"ubuntu" ]]; then
    if [[ ${os_version} -lt 16 ]]; then
        echo -e "${red}请使用 Ubuntu 16 或更高版本的系统！${plain}\n" && exit 1
    fi
elif [[ x"${release}" == x"debian" ]]; then
    if [[ ${os_version} -lt 8 ]]; then
        echo -e "${red}请使用 Debian 8 或更高版本的系统！${plain}\n" && exit 1
    fi
fi

install_base() {
    if [[ x"${release}" == x"centos" ]]; then
        yum install epel-release -y
        yum install wget curl unzip tar crontabs socat -y
    else
        apt install wget curl unzip tar cron socat -y
    fi
}

status1="未安装"
status2="未运行"
check_status() {
    if [[ -f /etc/systemd/system/XrayR.service ]]; then
        status1="已安装"
    fi
    temp=$(systemctl status XrayR | grep Active | awk '{print $3}' | cut -d "(" -f2 | cut -d ")" -f1)
    if [[ x"${temp}" == x"running" ]]; then
        status2="已运行"
    fi
}

install_acme() {
    curl https://get.acme.sh | sh
}

#安装完成显示的信息
After_install_menu() {
    echo
}

Panel_setting() {
    #设定前端地址
    echo "设定前端地址"
    echo ""
    read -p "请输入前端地址，例如：http://ml.abcdef.com：" panel_address
    [ -z "${panel_address}" ]
    echo "---------------------------"
    echo "您设定的前端地址为 ${panel_address}"
    echo "---------------------------"
    echo ""
    # 设定前端api key
    echo "设定api key"
    echo ""
    read -p "请输入服务器api key：" api_key
    [ -z "${api_key}" ]
    echo "---------------------------"
    echo "您设定的api key为 ${api_key}"
    echo "---------------------------"
    echo ""
    # 设置节点序号
    echo "设定节点序号"
    echo ""
    read -p "请输入V2Board中的节点序号：" node_id
    [ -z "${node_id}" ]
    echo "---------------------------"
    echo "您设定的节点序号为 ${node_id}"
    echo "---------------------------"
    echo ""
    # 选择协议
    echo "选择节点协议(默认V2ray)"
    echo ""
    read -p "请输入你使用的协议(V2ray, Shadowsocks, Trojan)：" node_type
    [ -z "${node_type}" ]
    # 如果不输入默认为V2ray
    if [ ! $node_type ]; then 
    node_type="V2ray"
    fi
    echo "---------------------------"
    echo "您选择的协议为 ${node_type}"
    echo "---------------------------"
    echo ""
}
Sspanel_panel() {
    echo -e "
Log:
  Level: warning # Log level: none, error, warning, info, debug 
  AccessPath: # /etc/XrayR/access.Log
  ErrorPath: # /etc/XrayR/error.log
DnsConfigPath: # /etc/XrayR/dns.json # Path to dns config, check https://xtls.github.io/config/dns.html for help
RouteConfigPath: # /etc/XrayR/route.json # Path to route config, check https://xtls.github.io/config/routing.html for help
InboundConfigPath: # /etc/XrayR/custom_inbound.json # Path to custom inbound config, check https://xtls.github.io/config/inbound.html for help
OutboundConfigPath: # /etc/XrayR/custom_outbound.json # Path to custom outbound config, check https://xtls.github.io/config/outbound.html for help
ConnetionConfig:
  Handshake: 4 # Handshake time limit, Second
  ConnIdle: 30 # Connection idle time limit, Second
  UplinkOnly: 2 # Time limit when the connection downstream is closed, Second
  DownlinkOnly: 4 # Time limit when the connection is closed after the uplink is closed, Second
  BufferSize: 64 # The internal cache size of each connection, kB 
Nodes:
  -
    PanelType: "SSpanel" # Panel type: SSpanel, V2board, PMpanel, , Proxypanel
    ApiConfig:
      ApiHost: "$panel_address"
      ApiKey: "$api_key"
      NodeID: $node_id
      NodeType: $node_type # Node type: V2ray, Shadowsocks, Trojan, Shadowsocks-Plugin
      Timeout: 30 # Timeout for the api request
      EnableVless: false # Enable Vless for V2ray Type
      EnableXTLS: false # Enable XTLS for V2ray and Trojan
      SpeedLimit: 0 # Mbps, Local settings will replace remote settings, 0 means disable
      DeviceLimit: 0 # Local settings will replace remote settings, 0 means disable
      RuleListPath: # /etc/XrayR/rulelist Path to local rulelist file
    ControllerConfig:
      ListenIP: 0.0.0.0 # IP address you want to listen
      SendIP: 0.0.0.0 # IP address you want to send pacakage
      UpdatePeriodic: 60 # Time to update the nodeinfo, how many sec.
      EnableDNS: false # Use custom DNS config, Please ensure that you set the dns.json well
      DNSType: AsIs # AsIs, UseIP, UseIPv4, UseIPv6, DNS strategy
      EnableProxyProtocol: false # Only works for WebSocket and TCP
      EnableFallback: false # Only support for Trojan and Vless
      FallBackConfigs:  # Support multiple fallbacks
        -
          SNI: # TLS SNI(Server Name Indication), Empty for any
          Alpn: # Alpn, Empty for any
          Path: # HTTP PATH, Empty for any
          Dest: 80 # Required, Destination of fallback, check https://xtls.github.io/config/features/fallback.html for details.
          ProxyProtocolVer: 0 # Send PROXY protocol version, 0 for dsable
      CertConfig:
        CertMode: dns # Option about how to get certificate: none, file, http, dns. Choose "none" will forcedly disable the tls config.
        CertDomain: "node1.test.com" # Domain to cert
        CertFile: /etc/XrayR/cert/node1.test.com.cert # Provided if the CertMode is file
        KeyFile: /etc/XrayR/cert/node1.test.com.key
        Provider: alidns # DNS cert provider, Get the full support list here: https://go-acme.github.io/lego/dns/
        Email: test@me.com
        DNSEnv: # DNS ENV option used by DNS provider
          ALICLOUD_ACCESS_KEY: aaa
          ALICLOUD_SECRET_KEY: bbb" > /usr/local/XrayR/config.yml
}
V2board_panel() {
    echo -e "
Log:
    Level: warning # Log level: none, error, warning, info, debug 
    AccessPath: # /etc/XrayR/access.Log
    ErrorPath: # /etc/XrayR/error.log
    DnsConfigPath: # /etc/XrayR/dns.json # Path to dns config, check https://xtls.github.io/config/dns.html for help
    RouteConfigPath: # /etc/XrayR/route.json # Path to route config, check https://xtls.github.io/config/routing.html for help
    InboundConfigPath: # /etc/XrayR/custom_inbound.json # Path to custom inbound config, check https://xtls.github.io/config/inbound.html for help
    OutboundConfigPath: # /etc/XrayR/custom_outbound.json # Path to custom outbound config, check https://xtls.github.io/config/outbound.html for help
    ConnetionConfig:
    Handshake: 4 # Handshake time limit, Second
    ConnIdle: 30 # Connection idle time limit, Second
    UplinkOnly: 2 # Time limit when the connection downstream is closed, Second
    DownlinkOnly: 4 # Time limit when the connection is closed after the uplink is closed, Second
    BufferSize: 64 # The internal cache size of each connection, kB 
Nodes:
 -
     PanelType: "V2board" # Panel type: SSpanel, V2board
     ApiConfig:
       ApiHost: "${panel_address}"
       ApiKey: "${api_key}"
       NodeID: ${node_id}
       NodeType: ${node_type} # Node type: V2ray, Shadowsocks, Trojan
       Timeout: 30 # Timeout for the api request
       EnableVless: false # Enable Vless for V2ray Type
       EnableXTLS: false # Enable XTLS for V2ray and Trojan
       SpeedLimit: 0 # Mbps, Local settings will replace remote settings
       DeviceLimit: 0 # Local settings will replace remote settings
     ControllerConfig:
       ListenIP: 0.0.0.0 # IP address you want to listen
       UpdatePeriodic: 10 # Time to update the nodeinfo, how many sec.
       EnableDNS: false # Use custom DNS config, Please ensure that you set the dns.json well
       CertConfig:
         CertMode: none # Option about how to get certificate: none, file, http, dns
         CertDomain: "node1.test.com" # Domain to cert
         CertFile: /etc/XrayR/cert/node1.test.com.cert # Provided if the CertMode is file
         KeyFile: /etc/XrayR/cert/node1.test.com.pem
  #       Provider: alidns # DNS cert provider, Get the full support list here: https://go-acme.github.io/lego/dns/
         Email: test@me.com
         DNSEnv: # DNS ENV option used by DNS provider
           ALICLOUD_ACCESS_KEY: aaa
           ALICLOUD_SECRET_KEY: bbb" > /usr/local/XrayR/config.yml


}

Download_XrayR() {
    install_base
    if [[ -e /usr/local/XrayR/ ]]; then
       rm /usr/local/XrayR/ -rf
    fi

    mkdir /usr/local/XrayR/ -p
	cd /usr/local/XrayR/

    if  [ $# == 0 ] ;then
        last_version=$(curl -Ls "https://api.github.com/repos/missuo/XrayR/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
        if [[ ! -n "$last_version" ]]; then
            echo -e "${red}检测 XrayR 版本失败，可能是超出 Github API 限制，请稍后再试，或手动指定 XrayR 版本安装${plain}"
            exit 1
        fi
        echo -e "${green}检测到 XrayR 最新版本：${last_version}，开始安装${plain}"
        wget -N --no-check-certificate -O /usr/local/XrayR/XrayR-linux-64.zip https://download.fastgit.org/missuo/XrayR/releases/download/${last_version}/XrayR-linux-64.zip
        if [[ $? -ne 0 ]]; then
            echo -e "${red}下载 XrayR 失败，请确保你的服务器能够下载 Github 的文件${plain}"
            exit 1
        fi
    else
        last_version=$1
        url="https://download.fastgit.org/missuo/XrayR/releases/download/${last_version}/XrayR-linux-64.zip"
        echo -e "开始安装 XrayR v$1"
        wget -N --no-check-certificate -O /usr/local/XrayR/XrayR-linux-64.zip ${url}
        if [[ $? -ne 0 ]]; then
            echo -e "${red}下载 XrayR v$1 失败，请确保此版本存在${plain}"
            exit 1
        fi
    fi
    

    unzip XrayR-linux-64.zip
    rm XrayR-linux-64.zip -f
    chmod +x XrayR
    mkdir /etc/XrayR/ -p
    cp geoip.dat /etc/XrayR/
    cp geosite.dat /etc/XrayR/ 
    rm /etc/systemd/system/XrayR.service -f
    #创建系统服务
    echo -e "[Unit]
Description=XrayR
After=network.target
Wants=network.target

[Service]
Type=simple
WorkingDirectory=/usr/local/XrayR/
ExecStart=/usr/local/XrayR/XrayR

[Install]
WantedBy=multi-user.target" > /etc/systemd/system/XrayR.service

    #cp -f XrayR.service /etc/systemd/system/
    #激活XrayR系统服务
    systemctl daemon-reload
    systemctl enable XrayR
    echo -e "${green}XrayR ${last_version}${plain} 安装完成"
   
}
Install_xrayr() {
    #下载XrayR管理脚本
    curl -o /usr/bin/XrayR -Ls https://raw.fastgit.org/missuo/XrayR-V2Board/master/XrayR.sh
    chmod +x /usr/bin/XrayR

    Download_XrayR
    Panel_setting
    echo -e "
    ${yellow}您的前端面板类型：${plain}
    1、V2Board
    2、sspanel"
    read -p "请输入序号：" input_type
    case $input_type in
    1) V2board_panel ;;
    2) Sspanel_panel ;;
    3) echo -e "${red}输入错误${plain}" && exit 1 ;;
    esac
    echo -e "${green}配置文件写入成功${plain}"
    echo -e "正在关闭防火墙！"
    echo
    systemctl disable firewalld
    systemctl stop firewalld
    #启动xrayr服务
    echo -e "${green}启动XrayR...${plain}"
    systemctl start XrayR
    sleep 2
    echo -e "${green}获取XrayR运行状态...${plain}"
    XrayR

}
Main_menu() {
    clear
    check_status
    echo -e "
    v2board状态：${green}$status1  $status2${plain}
    1.安装v2board
    2.启动v2board
    3.停止v2board
    4.卸载v2board
    5.回车退出"
    read -p "输入您的序号：" Main_menu_input
    case $Main_menu_input in
    1) Install_xrayr ;;
    2) systemctl start XrayR && check_status && echo -e "当前v2board $status2";;
    3) systemctl stop XrayR && check_status && echo -e "当前v2board $status2";;
    4) systemctl stop XrayR && systemctl disable XrayR && rm -rf /etc/systemd/system/XrayR.service && systemctl daemon-reload && rm -rf /usr/local/XrayR && echo -e "卸载完成" ;;
    *) exit 0 ;;
    esac
}



#install_acme
Main_menu