DESCRIPTION = "Provide access to MAVlink speaking flight controller, enabling RTK/PPK corrections via NTRIP servers"

LICENSE = "GPLv3"

require ../../../meta-ornl/recipes-core/images/ornl-prod-image.bb 

IMAGE_INSTALL_append += " \
    bash \
    ntrip-application \
    swupdate \
"