#!/bin/bash
# usage:
#   ensure-gpsd.sh [--dry-run]
#
# Ensure that all gpsd dependencies/modules needed are installed

DRY_RUN=false
SUDO=$(test ${EUID} -ne 0 && which sudo)

if [ "$1" == "--dry-run" ] ; then DRY_RUN=true && SUDO="echo ${SUDO}" ; fi
if [ ! "$1" == "--update" ] || ! [ -x apt-get ] ; then
	if ! gpsd -V ; then
		exit 1
	fi
	if ! [-x apt-get ] ; then exit 0 ; fi
fi

##PKGDEPS=gpsd gpsd-clients ntpstat
declare -A pkgdeps
pkgdeps[gpsd]=true
pkgdeps[gpsd-clients]=true
pkgdeps[ntpstat]=true

##PYTHONPKGS=pytz pynmea2
declare -A pydeps
pydeps[pytz]=">=2020.1"
pydeps[pynmea2]=">=1.15.0"

# with dry-run, just go thru packages and return an error if some are missing
if $DRY_RUN ; then
	declare -A todo
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
	if [ "${#todo[@]}" -gt 0 ] ; then echo "Please run: apt-get install -y ${!todo[@]}" ; fi
	exit ${#todo[@]}
	# python requirements
	echo "" > /tmp/$$.requirements
	for m in ${!pydeps[@]} ; do echo "$m${pydeps[$m]}" >> /tmp/$$.requirements ; done
	pip3 freeze -r /tmp/$$.requirements
	if pip3 freeze -r /tmp/$$.requirements ; then echo "Please run: pip3 install ${!pydeps[@]}" && exit 1 ; fi
	exit 0
fi
set -e
$SUDO apt-get install -y ${!pkgdeps[@]}
$SUDO pip3 install ${!pydeps[@]}

echo `gpsd -V`
