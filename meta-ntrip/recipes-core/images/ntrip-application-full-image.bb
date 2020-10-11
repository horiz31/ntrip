DESCRIPTION = "Provide access to MAVlink speaking flight controller, enabling RTK/PPK corrections via NTRIP servers"

require ../../../meta-ornl/recipes-core/images/ornl-prod-image.bb 

IMAGE_INSTALL_append += " \
    bash \
    ntrip-application \
    swupdate \
"
