#!/bin/bash
Install_BT() {
    echo -e "
    1.安装宝塔770
    2.卸载宝塔
    3.安装mdserver-web
    4.卸载mdserver-web
    5.回车取消"
    read -p "请输入序号：" BT_input
    case $BT_input in
    1) wget -O install.sh http://download.bt.cn/install/install-ubuntu_6.0.sh && sudo bash install.sh
    wget http://download.bt.cn/install/update/LinuxPanel-7.7.0.zip && unzip LinuxPanel-7.7.0.zip
    cd /root/panel && bash update.sh
    mv /www/server/panel/data/bind.pl bind.pl1
    bt ;;
    2) /etc/init.d/bt stop && chkconfig --del bt && rm -f /etc/init.d/bt && rm -rf /www/server/panel ;;
    3) curl -fsSL  https://gitee.com/midoks/mdserver-web/raw/master/scripts/install_cn.sh | bash ;;
    4) /etc/init.d/mw stop && rm -rf /www/server/mdserver-web ;;
    5) exit 0;;
    esac
    }
Install_BT
