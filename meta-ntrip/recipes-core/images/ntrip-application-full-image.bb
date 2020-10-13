DESCRIPTION = "Provide access to MAVlink speaking flight controller, enabling RTK/PPK corrections via NTRIP servers"

IMAGE_FEATURES += "ssh-server-dropbear splash "

require ../../../meta-ornl/recipes-core/images/ornl-dev-image.bb

IMAGE_INSTALL_append += " \
    bash \
    ntrip-application \
    python3-mavproxy \
    python3-pymavlink \
    swupdate \
    swupdate-www \
    kernel-image \
    kernel-devicetree \
    u-boot-variscite \
"
