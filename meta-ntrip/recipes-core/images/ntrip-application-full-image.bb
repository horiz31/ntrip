DESCRIPTION = "Provide access to MAVlink speaking flight controller, enabling RTK/PPK corrections via NTRIP servers"

# its not CLOSED, it GPLv3, but I can't figure out how to make damn Yocto not spit an error
LICENSE = "CLOSED"

require ../../../meta-ornl/recipes-core/images/ornl-prod-image.bb 

IMAGE_INSTALL_append += " \
    bash \
    ntrip-application \
    swupdate \
"
