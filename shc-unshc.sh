


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
#shc加密
Shc() {
    local shc_status="未安装"

    Install_shc1() {
    rm -f shc-3.8.9.tgz
    rm -rf /usr/local/man/man1
    rm -f /usr/local/bin/shc
    mkdir /usr/local/man/man1
    wget -N http://www.datsi.fi.upm.es/~frosal/sources/shc-3.8.9.tgz
    tar zxf shc-3.8.9.tgz 
    cd shc-3.8.9
    make
    make install
    yellow "安装完成"
    Show_shc_menu
    }
    Uninstall_shc1() {
    rm -f shc-3.8.9.tgz
    rm -rf /usr/local/man/man1
    rm -f /usr/local/bin/shc
    yellow "卸载完成"
    }
    Show_shc_menu() {

    echo -e "
    常用参数：
    -e  date （指定过期日期）
    -m  message （指定过期提示的信息） 
    -f  script_name（指定要编译的shell的路径及文件名）
    -r  Relax security. （可以相同操作系统的不同系统中执行）
    -v  Verbose compilation（编译的详细情况）

    使用方法：
    # shc -v -f abc.sh
    -f 后面跟需要加密的文件  ,运行后会生成两个文件: 
    abc.sh.x     为二进制文件，赋予执行权限后，可直接执行
    abc.sh.x.c   为c源文件。基本没用，可以删除

    # 设定有效执行期限的方法，如：
    # shc -e 28/01/2012 -m "过期了" -f abc.sh
    选项“-e”指定过期时间，格式为“日/月/年”；选项“-m”指定过期后执行此shell程序的提示信息"
    

    }
    Check_shc_status() {
        [[ -s /usr/local/bin/shc ]] && shc_status="已安装"

    }
    Check_shc_status
    echo ""
    echo ""
    yellow "加密工具shc：$shc_status"
    yellow "1.安装shc   2.卸载shc  3.回车取消"
    read -p "输入序号：" Input_shc
    case $Input_shc in
    1) Install_shc1 ;;
    2) Uninstall_shc1 ;;
    *)  ;;
    esac

}

#Unshc解密
Unshc() {
    wget -c -N --no-check-certificate -O /root/UnSHc.sh https://raw.fastgit.org/ppoonk/all/master/UnSHc.sh && chmod +x UnSHc.sh && ./UnSHc.sh

}
    echo ""
    echo ""
    yellow "
    1.shc加密脚本   
    2.unshc解密脚本
    3.回车取消"
    read -p "输入序号：" Input_shc
    case $Input_shc in
    1) Shc ;;
    2) Unshc ;;
    *)  ;;
    esac