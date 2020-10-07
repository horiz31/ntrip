SUMMARY = "NTRIP App Repo Pull"
DESCRIPTION = "Provide access to MAVlink speaking flight controller, enabling RTK/PPK corrections via NTRIP servers"
SECTION = "misc"
LICENSE = "GPLv3"
PR = "r0"

# Should pull the latest rev
SRCBRANCH="feature/YoctoLayerDev"
PV = "1.0+git${SRCPV}"
SRCREV= "${AUTOREV}"
SRC_URI = "git://github.com/uvdl/ntrip.git;protocol=https;branch=${SRCBRANCH}"

RDEPENDS_${PN} += " bash python3-core"

S="${WORKDIR}/git"

FILES_${PN} += "${prefix}/local/bin/*.sh"
FILES_${PN} += "${systemd_unitdir}/system/*.service"
FILES_${PN} += "${prefix}/local/bin/*.py"
FILES_${PN} += "${prefix}/local/src/ntrip/Makefile"

do_install() {
    install -d ${D}${prefix}/local/bin
    install -m 0755 ${S}/provision.sh ${D}${prefix}/local/bin
    install -m 0755 ${S}/ensure-network.sh ${D}${prefix}/local/bin
    install -m 0755 ${S}/Makefile ${D}${prefix}/local/src/ntrip

    if ${@bb.utils.contains('DISTRO_FEATURES','systemd','true','false',d)}; then
        install -d ${D}${systemd_unitdir}/system
        install -d ${D}${sysconfdir}/systemd/system/multi-user.target.wants
        install -m 0644 ${S}/mavproxy.service ${D}${systemd_unitdir}/system

        ln -sf ${systemd_unitdir}/system/mavproxy.service \
            ${D}${sysconfdir}/systemd/system/multi-user.target.wants/mavproxy.service
    fi

    # Create tar.gz for swupdates
    tar -czvf ${WORKDIR}/ntrip-application.tar.gz --directory=${S}/ * 
    mv -f ${WORKDIR}/ntrip-application.tar.gz ${WORKDIR}/../../../../../../sources/meta-ntrip/recipes-support/swupdate/ornl-ntrip-swu
}