#!/bin/bash
#==========================#
###### Author: CuteBi ######
#==========================#



#Print error message and exit.
Error() {
	echo $echo_e_arg "\033[41;37m$1\033[0m"
	echo -n "remove cns?[y]: "
	read remove
	echo "$remove"|grep -qi 'n' || Delete
	exit 1
}

#Make cns start cmd
Config() {
	[ -n "$cns_install_dir" ] && return  #Variables come from the environment
	echo -n "输入cns端口: "
	read cns_port
	echo -n "输入cns密钥(不需要请回车跳过): "
	read cns_encrypt_password
	echo -n "请输入cns udp标志(默认 'httpUDP'): "
	read cns_udp_flag
	echo -n "请输入cns代理密钥（默认值为“Meng”）: "
	read cns_proxy_key
	echo -n "请输入tls服务器端口（如果不需要，请回车跳过）: "
	read cns_tls_port
	echo -n "请输入cns安装目录（默认为/usr/local/cns）: "
	read cns_install_dir
	echo "${cns_install_dir:=/usr/local/cns}"
	echo -n "是否安装UPX压缩版本（如果不需要，请回车跳过）： "
	read cns_UPX
	echo "$cns_UPX"|grep -qi '^y' && cns_UPX="upx" || cns_UPX=""
}

GetAbi() {
	machine=`uname -m`
	#mips[...] use 'le' version
	if echo "$machine"|grep -q 'mips64'; then
		shContent=`cat "$SHELL"`
		[ "${shContent:5:1}" = `echo $echo_e_arg "\x01"` ] && machine='mips64le' || machine='mips64'
	elif echo "$machine"|grep -q 'mips'; then
		shContent=`cat "$SHELL"`
		[ "${shContent:5:1}" = `echo $echo_e_arg "\x01"` ] && machine='mipsle' || machine='mips'
	elif echo "$machine"|grep -Eq 'i686|i386'; then
		machine='386'
	elif echo "$machine"|grep -Eq 'armv7|armv6|armv7l'; then
		machine='arm'
	elif echo "$machine"|grep -Eq 'armv8|aarch64'; then
		machine='arm64'
	else
		machine='amd64'
	fi
}

#install cns files
InstallFiles() {
	GetAbi
	if echo "$machine" | grep -q '^mips'; then
		cat /proc/cpuinfo | grep -qiE 'fpu|neon|vfp|softfp|asimd' || softfloat='_softfloat'
	fi
	mkdir -p "$cns_install_dir" || Error "Create cns install directory failed."
	cd "$cns_install_dir" || exit 1
	wget --no-check-certificate -O cns http://binary.quicknet.cyou/cns/${cns_UPX}/linux_${machine}${softfloat} || Error "cns download failed."

	cat >cns.json <<-EOF
		{
			`[ -n "$cns_port" ] && echo '"Listen_addr": [":'$cns_port'"],'`
			"Proxy_key": "${cns_proxy_key:-Meng}",
			"Encrypt_password": "${cns_encrypt_password}",
			"Udp_flag": "${cns_udp_flag:-httpUDP}",
			"Enable_dns_tcpOverUdp": true,
			"Enable_httpDNS": true,
			"Enable_TFO": false,
			"Udp_timeout": 60,
			"Tcp_timeout": 600,
			"Pid_path": "${cns_install_dir}/run.pid"
			`[ -n "$cns_tls_port" ] && echo ',
			"Tls": {
					"Listen_addr": [":'$cns_tls_port'"]
				}'`
		}
	EOF
	chmod -R +rwx "$cns_install_dir" 
}


Install() {
	Config
	Delete >/dev/null 2>&1
	InstallFiles
    start
	echo $echo_e_arg \
		"cns安装成功.
		\r	cns server port:${cns_port}
		\r	cns proxy key:${cns_proxy_key:-Meng}
		\r	cns udp flag:${cns_udp_flag:-httpUDP}
		\r	cns encrypt password:${cns_encrypt_password}
		\r	cns tls server port:${cns_tls_port}
		"
}
#Stop cns & delete cns files.
Delete() {
    stop
	rm -rf "$cns_install_dir"
	
}
Uninstall() {
    if [ -z "$cns_install_dir" ]; then
		echo -n "请输入cns安装目录(默认为 /usr/local/cns，请直接回车): "
		read cns_install_dir
        [[ -z $cns_install_dir ]] && cns_install_dir="/usr/local/cns"
        echo "删除$cns_install_dir..."
	fi
	Delete >/dev/null 2>&1 && \
		echo $echo_e_arg "\n\033[44;37mcns卸载成功.\033[0m" || \
		echo $echo_e_arg "\n\033[41;37mcns卸载失败.\033[0m"
}

#script initialization
ScriptInit() {
	emulate bash 2>/dev/null #zsh emulation mode
	if echo -e ''|grep -q 'e'; then
		echo_e_arg=''
		echo_E_arg=''
	else
		echo_e_arg='-e'
		echo_E_arg='-E'
	fi
}

status() {
	{
		grep -q cns /proc/`cat "/usr/local/cns/run.pid" 2>/dev/null`/comm 2>/dev/null && \
			echo "cns 正在运行..." || \
			echo "cns 已停止..."
	} 2>/dev/null
}


start() {
	status | grep running && return 0
	echo -n "正在启动 cns:"
	cd "/usr/local/cns"
	./cns -json=cns.json -daemon >/dev/null
	sleep 1
	grep -q cns /proc/`cat /usr/local/cns/run.pid 2>/dev/null`/comm && \
		echo -e "\033[60G[\033[32m  OK  \033[0m]" || \
		echo -e "\033[60G[\033[31mFAILED\033[0m]"
}

stop() {
	status | grep stopped && return 0
	echo -n "正在停止 cns:"
	kill `cat /usr/local/cns/run.pid 2>/dev/null` 2>/dev/null
	sleep 1
	grep -q cns /proc/`cat /usr/local/cns/run.pid`/comm 2>/dev/null && \
		echo -e "\033[60G[\033[31mFAILED\033[0m]" || \
		echo -e "\033[60G[\033[32m  OK  \033[0m]"
}

restart() {
	stop
	start
}

menu() {
    echo "
    1、安装并启动cns
    2、重启
    3、停止
    4、卸载"
    read -p "输入序号：" cnsinput
    case "$cnsinput" in
        1) Install ;;
        2) restart ;;
        3) stop ;;
        4) Uninstall ;;
    esac
}
ScriptInit
menu

