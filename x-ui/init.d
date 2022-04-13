#!/sbin/openrc-run

name="xray"
description="The best v2ray-core, with XTLS support"
description_checkconfig="Test configuration file"

#: ${env:="XRAY_LOCATION_ASSET=/usr/local/xray/"}
#: ${confdir:="/usr/local/xray/"}

command="/usr/local/xray/xray"
#command_args="run -confdir $confdir"
command_user="nobody"

pidfile="/run/xray.pid"
command_background="yes"

#extra_commands="checkconfig"

depend() {
	need net
}

#checkconfig() {
#	if [ ! -d "$confdir" ]; then
#		eerror "You need to setup $confdir first"
#		return 1
#	fi
#	export $env
#	$command $command_args -test
#}

#start_pre() {
#	checkconfig
}