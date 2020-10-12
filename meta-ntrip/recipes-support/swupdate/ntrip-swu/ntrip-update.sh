#!/bin/sh

if [ $# -lt 1 ]; then
	exit 0;
fi

if [ $1 == "preinst" ] ; then
	# must exist, else swupdate will fail
	mkdir -p /usr/local/src/ntrip
	exit 0
fi

if [ $1 == "postinst" ] ; then
	rm -f /usr/local/src/ntrip/ntrip-application.tar.gz
	make -C /usr/local/src/ntrip install
	stty -F /dev/ttymxc3 cs8 -parenb -cstopb
	/usr/local/src/ntrip/ensure-network.sh
	exit 0
fi
