#!/bin/sh

if [ $# -lt 1 ]; then
	exit 0;
fi

if [ $1 == "preinst" ] ; then
	# Remove files in /usr/local/src/ntrip
	rm -f /usr/local/src/ntrip/ensure-network.sh
	rm -f /usr/local/src/ntrip/provision.sh
	rm -f /usr/local/src/ntrip/Makefile
	exit 0
fi

if [ $1 == "postinst" ] ; then
	rm /usr/local/src/ntrip/ntrip-application.tar.gz
	mv -f /usr/local/src/ntrip/*.service /lib/systemd/system/
	exit 0
fi
