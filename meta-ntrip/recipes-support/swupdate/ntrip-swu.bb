DESCRIPTION = "Artifact recipe for the NTRIP Application"
SECTION = ""

inherit swupdate

LICENSE = "GPLv3"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/GPL-3.0;md5=c79ff39f19dfec6d293b95dea7b07891"

# Note: sw-description is mandatory
SRC_URI = " \
	file://ntrip-application.tar.gz \
	file://sw-description \
	file://ntrip-update.sh \
"

# IMAGE_DEPENDS: list of Yocto images that contains a root filesystem
# it will be ensured they are built before creating swupdate image
IMAGE_DEPENDS = " \
	ntrip-application \
"

SWUPDATE_IMAGES_NOAPPEND_MACHINE[var-som-mx6-ornl] = "1"

# Images can have multiple formats - define which image must be
# taken to be put in the compound image
SWUPDATE_IMAGES_FSTYPES[ntrip-application] = ".tar.gz"
