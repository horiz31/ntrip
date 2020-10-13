SUMMARY = "NTRIP App Repo Pull"
DESCRIPTION = "Provide access to MAVlink speaking flight controller, enabling RTK/PPK corrections via NTRIP servers"
SECTION = "misc"
LICENSE = "GPLv3"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/GPL-3.0;md5=c79ff39f19dfec6d293b95dea7b07891"
PR = "r8"

# Should pull the latest rev
SRCBRANCH="bfg"
PV = "1.0+git${SRCPV}"
SRCREV= "${AUTOREV}"
SRC_URI = "git://github.com/horiz31/ntrip.git;protocol=https;branch=${SRCBRANCH}"

RDEPENDS_${PN} += " bash python3-core python3-netifaces python3-future sudo"

S="${WORKDIR}/git"

FILES_${PN} += "${prefix}/local/src/ntrip/*.sh"
FILES_${PN} += "${systemd_unitdir}/system/*.service"
FILES_${PN} += "${prefix}/local/src/ntrip/*.py"
FILES_${PN} += "${prefix}/local/src/ntrip/Makefile"
FILES_${PN} += "${prefix}/local/src/ntrip/LICENSE"
FILES_${PN} += "${prefix}/local/src/ntrip/config/*.conf"

# NB: it appears that the below only gets called when creating a rootfs image
# when using the software update image, the below needs to be performed
# in the postinst portion of the ntrip-update.sh
do_install() {
    mkdir -p ${D}${prefix}/local/src
    install -d ${D}${prefix}/local/src/ntrip
    install -m 0755 ${S}/provision.sh ${D}${prefix}/local/src/ntrip
    install -m 0755 ${S}/ensure-network.sh ${D}${prefix}/local/src/ntrip
    install -m 0644 ${S}/Makefile ${D}${prefix}/local/src/ntrip
    install -m 0644 ${S}/LICENSE ${D}${prefix}/local/src/ntrip

    if ${@bb.utils.contains('DISTRO_FEATURES','systemd','true','false',d)}; then
        install -d ${D}${systemd_unitdir}/system
        install -d ${D}${sysconfdir}/systemd/system/multi-user.target.wants
        install -m 0644 ${S}/mavproxy.service ${D}${systemd_unitdir}/system

        ln -sf ${systemd_unitdir}/system/mavproxy.service \
            ${D}${sysconfdir}/systemd/system/multi-user.target.wants/mavproxy.service
    fi

    # provide customer-specific configuration files for non-interactive software update
    install -d ${D}/etc/systemd
    install -m 0644 ${S}/config/gpsd.conf ${D}/etc/systemd
    install -m 0644 ${S}/config/mavproxy.conf ${D}/etc/systemd
    install -m 0644 ${S}/config/network.conf ${D}/etc/systemd
    install -m 0644 ${S}/config/ntpd.conf ${D}/etc/systemd
    install -m 0644 ${S}/config/etc-ntp.conf ${D}/etc/ntp.conf

    # Create tar.gz for swupdates
    tar -czvf ${WORKDIR}/ntrip-application.tar.gz --directory=${S}/ * 
    mv -f ${WORKDIR}/ntrip-application.tar.gz ${WORKDIR}/../../../../../../sources/meta-ntrip/recipes-support/swupdate/ntrip-swu
}
