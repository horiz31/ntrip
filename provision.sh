#!/bin/bash
# usage:
#   provision.sh filename [--dry-run]
#
# Interactively create/update a systemd service configuration file
#

SUDO=$(test ${EUID} -ne 0 && which sudo)
SYSCFG=/etc/systemd
UDEV_RULESD=/etc/udev/rules.d

CONF=$1
shift
DEFAULTS=false
DRY_RUN=false
while (($#)) ; do
	if [ "$1" == "--dry-run" ] && ! $DRY_RUN ; then DRY_RUN=true ;
	elif [ "$1" == "--defaults" ] ; then DEFAULTS=true ;
	fi
	shift
done

# https://stackoverflow.com/questions/20762575/explanation-of-convertor-of-cidr-to-netmask-in-linux-shell-netmask2cdir-and-cdir
function cidr2mask {
	# Number of args to shift, 255..255, first non-255 byte, zeroes
	set -- $(( 5 - ($1 / 8) )) 255 255 255 255 $(( (255 << (8 - ($1 % 8))) & 255 )) 0 0 0
	[ $1 -gt 1 ] && shift $1 || shift
	echo ${1-0}.${2-0}.${3-0}.${4-0}
}

function ip2network {
	if [ -z "$2" ] ; then
		IFS=". /" read -r i1 i2 i3 i4 mask <<< $1
		IFS=" ." read -r m1 m2 m3 m4 <<< $(cidr2mask $mask)
	else
		IFS=". " read -r i1 i2 i3 i4 <<< $1
		IFS=" ." read -r m1 m2 m3 m4 <<< $2
	fi
	printf "%d.%d.%d.%d\n" "$((i1 & m1))" "$((i2 & m2))" "$((i3 & m3))" "$((i4 & m4))"
}

function address_of {
	local result=$(ip addr show $1 | grep inet | grep -v inet6 | head -1 | sed -e 's/^[[:space:]]*//' | cut -f2 -d' ' | cut -f1 -d/)
	echo $result
}

function value_of {
	local result=$($SUDO grep $1 $CONF 2>/dev/null | cut -f2 -d=)
	if [ -z "$result" ] ; then result=$2 ; fi
	echo $result
}

# pull default provisioning items from the network.conf (generate it first)
function value_from_network {
	local result=$($SUDO grep $1 $(dirname $CONF)/network.conf 2>/dev/null | cut -f2 -d=)
	if [ -z "$result" ] ; then result=$2 ; fi
	echo $result
}

function interactive {
	local result
	read -p "${2}? ($1) " result
	if [ -z "$result" ] ; then result=$1 ; elif [ "$result" == "*" ] ; then result="" ; fi
	echo $result
}

function contains {
	local result=no
	#if [[ " $2 " =~ " $1 " ]] ; then result=yes ; fi
	if [[ $2 == *"$1"* ]] ; then result=yes ; fi
	echo $result
}

# configuration values used in this script
declare -A config
config[iface]=$(value_from_network IFACE wlan0)

case "$(basename $CONF)" in
	mavproxy.conf)
		# TODO: mavproxy --out needs udp or udpbcast (or udpmcast?) based on HOST  (see mavproxy.service)
		BAUD=$(value_of BAUD 115200)
		DEVICE=$(value_of DEVICE /dev/autopilot)
		FLAGS=($(value_of FLAGS ""))
		_FLOW=$(contains "--rtscts" "${FLAGS[@]}")
		IFACE=$(value_of IFACE ${config[iface]})
		HOST=$(value_of HOST $(echo $(address_of ${IFACE}) | cut -f1,2 -d.).255.255)
		PORT=$(value_of PORT 14550)
		SYSID=$(value_of SYSID 1)
		if ! $DEFAULTS ; then
			IFACE=$(interactive "$IFACE" "UDP Interface for telemetry")
			HOST=$(interactive "$HOST" "UDP IPv4 for telemetry")
			PORT=$(interactive "$PORT" "UDP PORT for telemetry")
			DEVICE=$(interactive "$DEVICE" "Serial Device for flight controller")
			BAUD=$(interactive "$BAUD" "Baud rate for flight controller")
			_FLOW=$(interactive "$_FLOW" "RTS/CTS Flow Control")
			SYSID=$(interactive "$SYSID" "System ID of the flight controller")
			
		fi
		# Different systems have mavproxy installed in various places
		MAVPROXY=/usr/bin/mavproxy.py
		# mavproxy wants LOCALAPPDATA to be valid
		LOCALAPPDATA='/tmp'
		# FLAGS must keep the --rtscts as that is what mavproxy uses
		if [ "${_FLOW}" == "on" ] || [[ ${_FLOW} == y* ]] ; then
			if [[ ! " ${FLAGS[@]} " =~ " --rtscts " ]] ; then FLAGS=(--rtscts) ; fi
		else
			# BUT! FLAGS cannot be empty for systemd, so we pick something benign
			FLAGS=(--nodtr)
		fi
		# Need to track what type of --out device to use, based on HOST (udp, udpbcast)
		# NB: mavproxy.py only intrprets udp or udpbcast.
		# NB: mavproxy.py udpbcast does not work as of 2020-05-15 or so.
		if [[ $HOST == *255* ]] ; then PROTOCOL=udpbcast ; else PROTOCOL=udp ; fi
		# https://forums.developer.nvidia.com/t/jetson-nano-how-to-use-uart-on-ttyths1/82037
		if ! $DRY_RUN ; then
			#set -x
			if [ "${DEVICE}" == "/dev/ttyTHS1" ] ; then
				$SUDO systemctl stop nvgetty && \
				$SUDO systemctl disable nvgetty
			fi
			if [ -c ${DEVICE} ] ; then
				$SUDO chown root:dialout ${DEVICE} && \
				$SUDO chmod 660 ${DEVICE}
				# https://stackoverflow.com/questions/41266001/screen-dev-ttyusb0-with-different-options-such-as-databit-parity-etc/52391586
				opts=(cs8 -parenb -cstopb)	# 8N1
				if [[ " ${FLAGS[@]} " =~ " --rtscts " ]] ; then opts+=(crtscts) ; fi
				stty -F ${DEVICE} "${opts[@]}"
			fi
			#set +x
		fi
		echo "[Service]" > /tmp/$$.env && \
		echo "BAUD=${BAUD}" >> /tmp/$$.env && \
		echo "DEVICE=${DEVICE}" >> /tmp/$$.env && \
		echo "FLAGS=${FLAGS[@]}" >> /tmp/$$.env && \
		echo "IFACE=${IFACE}" >> /tmp/$$.env && \
		echo "PROTOCOL=${PROTOCOL}" >> /tmp/$$.env && \
		echo "HOST=${HOST}" >> /tmp/$$.env && \
		echo "LOCALAPPDATA=${LOCALAPPDATA}" >> /tmp/$$.env && \
		echo "MAVPROXY=${MAVPROXY}" >> /tmp/$$.env && \
		echo "PORT=${PORT}" >> /tmp/$$.env && \
		echo "SYSID=${SYSID}" >> /tmp/$$.env
		;;

	network.conf)
		IFACE=$(value_of IFACE eth0)
		HOST=$(value_of HOST $(address_of ${IFACE}))
		GATEWAY=$(value_of GATEWAY "")
		NETMASK=$(value_of NETMASK 16)
		if ! $DEFAULTS ; then
			IFACE=$(interactive "$IFACE" "RJ45 Network Interface")
			HOST=$(interactive "$HOST" "IPv4 for RJ45 Network")
			GATEWAY=$(interactive "$GATEWAY" "IPv4 gateway for RJ45 Network")
			NETMASK=$(interactive "$NETMASK" "CDIR/netmask for RJ45 Network")
		fi
		echo "[Service]" > /tmp/$$.env && \
		echo "IFACE=${IFACE}" >> /tmp/$$.env && \
		echo "HOST=${HOST}" >> /tmp/$$.env && \
		echo "GATEWAY=${GATEWAY}" >> /tmp/$$.env && \
		echo "NETMASK=${NETMASK}" >> /tmp/$$.env
		;;

	gpsd.conf)
		# special case of provisioning GPS:  gpsd is setup to
		# read /etc/default/gpsd, but we are keeping our own config
		# in /etc/systemd/gpsd.conf
		CONFIG=/etc/default/gpsd
		MODEL=$(value_of MODEL M8N)
		if ! $DEFAULTS ; then
			lsusb
			MODEL=$(interactive "$MODEL" "GPS Model")
		fi
		if ! $DRY_RUN ; then
			# TODO: need a cross-reference between model and VID/PID
			# NB: this code is not needed for the yocto builds with gpsd that comes configured with udev rules for several GPS including the M8N
			if [[ $(contains "M8P" "$MODEL") == y* ]] || [[ $(contains "M8N" "$MODEL") == y* ]] ; then
				cat > /tmp/$$.gps.rules <<- GPSRULES
SUBSYSTEMS=="usb", KERNEL=="ttyACM?", ATTRS{idVendor}=="1546", ATTRS{idProduct}=="01a8", SYMLINK+="gps"
GPSRULES
			fi
			if diff /tmp/$$.gps.rules ${UDEV_RULESD}/99-gps.rules > /dev/null ; then
				set -x
				$SUDO install -Dm644 /tmp/$$.gps.rules ${UDEV_RULESD}/99-gps.rules
				$SUDO udevadm control --reload-rules && $SUDO udevadm trigger
				set +x
			fi
			# setup gpsd to make the GPS available to the local system
			# NB: there is a message in /etc/default/gpsd to not edit the file directly but use 'dpkg-reconfigure gpsd' to reconfigure
			cat > /tmp/$$.gpsd.conf <<- GPSCONFIG
START_DAEMON="true"
USBAUTO="true"
DEVICES="/dev/gps"
GPSD_OPTIONS="-n"
GPSCONFIG
			if diff /tmp/$$.gpsd.conf ${CONFIG} > /dev/null ; then
				set -x
				$SUDO install -Dm644 /tmp/$$.gpsd.conf ${CONFIG}
				$SUDO systemctl restart gpsd
				sleep 2
				gpspipe -r -n 20 127.0.0.1 2947
				set +x
			fi
		fi
		echo "[Service]" > /tmp/$$.env && \
		echo "CONFIG=${CONFIG}" >> /tmp/$$.env && \
		echo "MODEL=${MODEL}" >> /tmp/$$.env
		;;

	ntpd.conf)
		# special case of provisioning NTP:  ntpd is setup to
		# read /etc/ntp.conf, but we are keeping our own config
		# in /etc/systemd/ntpd.conf
		CONFIG=/etc/ntp.conf
		SYNC=$(value_of SYNC gps)
		if ! $DEFAULTS ; then
			SYNC=$(interactive "$SYNC" "Sync time from GPS or NET")
		fi
		if ! $DRY_RUN ; then
			if [[ $(contains "gps" "$SYNC") == y* ]] ; then
				cat > /tmp/$$.ntp <<- SYNCGPS
pool us.pool.ntp.org iburst

driftfile /var/lib/ntp/ntp.drift
logfile /var/log/ntp.log

restrict default kod nomodify notrap nopeer noquery
restrict -6 default kod nomodify notrap nopeer noquery
restrict 127.0.0.1 mask 255.255.255.0
restrict -6 ::1

# GPS Serial data reference (NTP0)
server 127.127.28.0
fudge 127.127.28.0 time1 0.138 flag1 1 refid GPS

# GPS PPS reference (NTP1)
server 127.127.28.2 prefer
fudge 127.127.28.2 flag1 1 refid PPS
SYNCGPS
			else
				# https://www.ntppool.org/zone/north-america
				# https://www.ntppool.org/vendors.html
				cat > /tmp/$$.ntp <<- SYNCNET
statistics loopstats peerstats clockstats
filegen loopstats file loopstats type day enable
filegen peerstats file peerstats type day enable
filegen clockstats file clockstats type day enable

pool 0.north-america.pool.ntp.org iburst
pool 1.north-america.pool.ntp.org iburst
pool 2.north-america.pool.ntp.org iburst
pool 3.north-america.pool.ntp.org iburst

restrict -4 default kod notrap nomodify nopeer noquery limited
restrict -6 default kod notrap nomodify nopeer noquery limited

restrict 127.0.0.1
restrict ::1

restrict source notrap nomodify noquery
SYNCNET
			fi
			if diff /tmp/$$.ntp $CONFIG > /dev/null ; then
				set -x
				$SUDO killall -9 ntpd
				$SUDO install -Dm644 /tmp/$$.ntp $CONFIG
				ntpd -gN
				sleep 2
				ntpq -p
				date
				set +x
			fi
		fi
		echo "[Service]" > /tmp/$$.env && \
		echo "CONFIG=${CONFIG}" >> /tmp/$$.env && \
		echo "SYNC=${SYNC}" >> /tmp/$$.env
		;;

	*)
		# preserve contents or generate a viable empty configuration
		echo "[Service]" > /tmp/$$.env
		;;
esac

if $DRY_RUN ; then
	echo $CONF && cat /tmp/$$.env && echo ""
elif [[ $(basename $CONF) == *.sh ]] ; then
	$SUDO install -Dm755 /tmp/$$.env $CONF
else
	$SUDO install -Dm644 /tmp/$$.env $CONF
fi
rm /tmp/$$.env
