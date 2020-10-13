#!/bin/bash

S=/usr/local/src/ntrip
D=
systemd_unitdir=/lib/systemd

if [ $# -lt 1 ]; then
	exit 0;
fi

if [ $1 == "preinst" ] ; then
	# must exist, else swupdate will fail
	mkdir -p ${S}
	exit 0
fi

if [ $1 == "postinst" ] ; then
	# remove tarball from upload
	rm -f ${S}/ntrip-application.tar.gz
	# put config files in the needed places
	install -m 0644 ${S}/config/gpsd.conf ${D}/etc/systemd
	install -m 0644 ${S}/config/mavproxy.conf ${D}/etc/systemd
	install -m 0644 ${S}/config/network.conf ${D}/etc/systemd
	install -m 0644 ${S}/config/ntpd.conf ${D}/etc/systemd
	install -m 0644 ${S}/config/etc-ntp.conf ${D}/etc/ntp.conf
	install -m 0644 ${S}/ensure-network.service ${D}${systemd_unitdir}/system/ensure-network.service
	install -m 0644 ${S}/mavproxy.service ${D}${systemd_unitdir}/system/mavproxy.service
	systemctl daemon-reload
	systemctl enable ensure-network mavproxy
	# ensure the FMU uart is in the right mode for mavlink I/O
	stty -F /dev/ttymxc3 cs8 -parenb -cstopb
	exit 0
fi
