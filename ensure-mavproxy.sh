#!/bin/bash
# usage:
#   ensure-mavproxy.sh [--dry-run]
#
# Ensure that all mavproxy dependencies/modules needed are installed
#
# https://ardupilot.github.io/MAVProxy/html/getting_started/download_and_installation.html

DRY_RUN=false
SUDO=$(test ${EUID} -ne 0 && which sudo)
MAVPROXY=$(which mavproxy.py)

if [ "$1" == "--dry-run" ] ; then DRY_RUN=true ; fi
if ! [ -z "$MAVPROXY" ] ; then
	MAVPROXY_VERSION=$(python3 $MAVPROXY --version)
	if ! [ -z "${MAVPROXY_VERSION}" ] ; then
		echo "${MAVPROXY_VERSION}"
		exit 0
	fi
	exit 1
fi

##PKGDEPS=python3-dev python3-opencv python3-wxgtk3.0 python3-pip python3-matplotlib python3-pygame python3-lxml python3-yaml
declare -A pkgdeps
pkgdeps[libxml2-dev]=true
pkgdeps[libxslt-dev]=true
pkgdeps[python3-dev]=true
pkgdeps[python3-lxml]=true
#pkgdeps[python3-matplotlib]=true
#pkgdeps[python3-opencv]=true
pkgdeps[python3-pip]=true
#pkgdeps[python3-pygame]=true
#pkgdeps[python3-wxgtk3.0]=true
pkgdeps[python3-yaml]=true

# with dry-run, just go thru packages and return an error if some are missing
if $DRY_RUN ; then
	declare -A todo
	if [ -x apt ] ; then
		apt list --installed > /tmp/$$.pkgs 2>/dev/null	# NB: warning on stderr about unstable API
		for m in ${!pkgdeps[@]} ; do
			x=$(grep $m /tmp/$$.pkgs)
			if [ -z "$x" ] ; then
				echo "$m: missing"
				todo[$m]=true
			else
				true #&& echo "$x"
			fi
		done
	# TODO: check for mavproxy installed in python"
	fi
	if [ "${#todo[@]}" -gt 0 ] ; then echo "Please run: apt-get install -y ${!todo[@]}" ; fi
	exit ${#todo[@]}
fi
# MAVProxy wants you to *uninstall* ModemManager (not simply ensure it doesn't run)
$SUDO systemctl stop ModemManager
set -e
if [ -x apt-get ] ; then
	$SUDO apt-get remove -y modemmanager
	$SUDO apt-get install -y ${!pkgdeps[@]}
fi
if [ -z "$SUDO" ] ; then
	pip3 install --upgrade MAVProxy
else
	$SUDO -H pip3 install --upgrade MAVProxy
fi
MAVPROXY=$(which mavproxy.py)
echo "$(python3 $MAVPROXY --version)"
