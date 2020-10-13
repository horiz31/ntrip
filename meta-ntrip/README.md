This README file contains information on the contents of the ../sources/meta-ntrip layer.

***IMPORTANT
In order to run bitbake and build the NTRIP SWU image, you first have to build the ntrip-application recipe.***

bitbake ntrip-application

This will create a tar.gz file in the swuupdate folder and attach it to the .swu that is sent to the device.

Please see the corresponding sections below for details.

## Patches

Please submit any pull requests against the `meta-ntrip` layer to https://github.com/uvdl/ntrip

## Adding the ../sources/meta-ntrip layer to your build environment

**(ensure you are in your build environment.  That means you have done setup-environment in your shell.)**

 1. copy this (`meta-ntrip`) folder to `$YOCTO_DIR/sources/meta-ntrip`
 2. from `$YOCTO_DIR/$YOCTO_ENV`, run `bitbake-layers add-layer ../sources/meta-ntrip`

## Building

**(ensure you are in your build environment.  That means you have done setup-environment in your shell.)**

 1. from `$YOCTO_DIR/$YOCTO_ENV`, run `bitbake ntrip-application`
 2. from `$YOCTO_DIR/$YOCTO_ENV`, run `bitbake ntrip-swu`

Then there will be a file with a `.swu` extension built that you can upload to your device to update the software.
You will then need to connect to a console and `make provision` in the `/usr/local/src/ntrip` folder.
