DESCRIPTION = "Provide access to MAVlink speaking flight controller, enabling RTK/PPK corrections via NTRIP servers"

# its not CLOSED, it GPLv3, but I can't figure out how to make damn Yocto not spit an error
LICENSE = "CLOSED"

require ntrip-application-full-image.bb ../../meta-ornl/recipes-core/images/var-prod-update-full-image.bb
