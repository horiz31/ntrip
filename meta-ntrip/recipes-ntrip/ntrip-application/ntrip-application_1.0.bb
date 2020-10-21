SUMMARY = "NTRIP App Repo Pull"
DESCRIPTION = "Provide access to MAVlink speaking flight controller, enabling RTK/PPK corrections via NTRIP servers"
SECTION = "misc"
LICENSE = "GPLv3"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/GPL-3.0;md5=c79ff39f19dfec6d293b95dea7b07891"
PR = "r14"

# Should pull the latest rev
SRCBRANCH="fix/rootfs"
PV = "1.0+git${SRCPV}"
SRCREV= "${AUTOREV}"
SRC_URI = "git://github.com/horiz31/ntrip.git;protocol=https;branch=${SRCBRANCH}"

RDEPENDS_${PN} += " bash python3-core python3-netifaces python3-future sudo"

S="${WORKDIR}/git"

FILES_${PN} += " \
	${prefix}/local/src/ntrip/LICENSE \
	${prefix}/local/src/ntrip/Makefile \
	${prefix}/local/src/ntrip/provision.sh \
	${prefix}/local/src/ntrip/README.md \
"
FILES_${PN} += " \
	${prefix}/local/bin/ensure-network.sh \
"
FILES_${PN} += " \
	${systemd_unitdir}/system/ensure-network.service \
	${systemd_unitdir}/system/mavproxy.service \
"
# https://stackoverflow.com/questions/38099893/yocto-linux-module-recipe-do-package-qa-error
# which is unintelligible, but basically says no ${D} in FILES_${PN}...  I am assuming
# that ${prefix} is /usr so I dont want that...  And ${prefix}/../etc would be wierd...
FILES_${PN} += " \
	/etc/ntp.conf \
	/etc/systemd/gpsd.conf \
	/etc/systemd/mavproxy.conf \
	/etc/systemd/network.conf \
	/etc/systemd/ntpd.conf \
"

# NB: it appears that the below only gets called when creating a rootfs image
# when using the software update image, the below needs to be performed
# in the postinst portion of the ntrip-update.sh
do_install() {
	mkdir -p ${D}${prefix}/local/src
	install -d ${D}${prefix}/local/src/ntrip
	install -m 0644 ${S}/LICENSE ${D}${prefix}/local/src/ntrip
	install -m 0644 ${S}/Makefile ${D}${prefix}/local/src/ntrip
	install -m 0755 ${S}/provision.sh ${D}${prefix}/local/src/ntrip
	install -m 0644 ${S}/README.md ${D}${prefix}/local/src/ntrip

	mkdir -p ${D}${prefix}/local/bin
	install -m 0755 ${S}/ensure-network.sh ${D}${prefix}/local/bin

	# provide customer-specific configuration files for non-interactive software update
	install -d ${D}/etc
	install -m 0644 ${S}/config/etc-ntp.conf ${D}/etc/ntp.conf
	install -d ${D}/etc/systemd
	install -m 0644 ${S}/config/gpsd.conf ${D}/etc/systemd
	install -m 0644 ${S}/config/mavproxy.conf ${D}/etc/systemd
	install -m 0644 ${S}/config/network.conf ${D}/etc/systemd
	install -m 0644 ${S}/config/ntpd.conf ${D}/etc/systemd

    if ${@bb.utils.contains('DISTRO_FEATURES','systemd','true','false',d)}; then
	install -d ${D}${systemd_unitdir}/system
	install -m 0644 ${S}/ensure-network.service ${D}${systemd_unitdir}/system
	install -m 0644 ${S}/mavproxy.service ${D}${systemd_unitdir}/system

	install -d ${D}${sysconfdir}/systemd/system/multi-user.target.wants
	ln -sf ${systemd_unitdir}/system/ensure-network.service \
		${D}${sysconfdir}/systemd/system/multi-user.target.wants/ensure-network.service
	ln -sf ${systemd_unitdir}/system/mavproxy.service \
		${D}${sysconfdir}/systemd/system/multi-user.target.wants/mavproxy.service
    fi

	# Create tar.gz for swupdates
	tar -czvf ${WORKDIR}/ntrip-application.tar.gz --directory=${S}/ * 
	mv -f ${WORKDIR}/ntrip-application.tar.gz ${WORKDIR}/../../../../../../sources/meta-ntrip/recipes-support/swupdate/ntrip-swu
}
