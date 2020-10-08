SUMMARY = "NTRIP App Repo Pull"
DESCRIPTION = "Provide access to MAVlink speaking flight controller, enabling RTK/PPK corrections via NTRIP servers"
SECTION = "misc"
#LICENSE = "CLOSED"
# its not CLOSED, it GPLv3, but I can't figure out how to make damn Yocto not spit an error
LICENSE = "GPLv3"
LIC_FILES_CHKSUM = "file://LICENSE;md5=1ebbd3e34237af26da5dc08a4e440464"
PR = "r2"

# Should pull the latest rev
SRCBRANCH="feature/YoctoLayerDev"
PV = "1.0+git${SRCPV}"
SRCREV= "${AUTOREV}"
SRC_URI = "git://github.com/uvdl/ntrip.git;protocol=https;branch=${SRCBRANCH}"

RDEPENDS_${PN} += " bash python3-core"

S="${WORKDIR}/git"

FILES_${PN} += "${prefix}/local/src/ntrip/*.sh"
FILES_${PN} += "${systemd_unitdir}/system/*.service"
FILES_${PN} += "${prefix}/local/src/ntrip/*.py"
FILES_${PN} += "${prefix}/local/src/ntrip/Makefile"
FILES_${PN} += "${prefix}/local/src/ntrip/LICENSE"

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

    # Create tar.gz for swupdates
    tar -czvf ${WORKDIR}/ntrip-application.tar.gz --directory=${S}/ * 
    mv -f ${WORKDIR}/ntrip-application.tar.gz ${WORKDIR}/../../../../../../sources/meta-ntrip/recipes-support/swupdate/ornl-ntrip-swu
}
