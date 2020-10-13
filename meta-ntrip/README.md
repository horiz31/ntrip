# ntrip/meta-ntrip

This file contains information on the contents of the ../sources/meta-ntrip layer.

***IMPORTANT
In order to run bitbake and build the NTRIP SWU image, you have to configure your Yocto build environment.
***

## Configuring your build environment

You will need a build environment for the pixc4.  This is setup thru the `pixc4` branch of this fork:
https://github.com/horiz31/yocto-ornl

### Quick Start

```
cd $HOME
git clone https://github.com/horiz31/yocto-ornl.git -b pixc4
( cd yocto-ornl && make dependencies && make environment )
```

**NOTE: `make dependencies` only needs to be done once on a build machine.**
**NOTE: by default, `make environment` will setup your Yocto environment into `$HOME/ornl-dart-yocto/build_ornl`.**

You **must** follow the instructions at the end of the above environment update script.  The Yocto build system is based on many environment variables set in your current shell.  These are **NOT** portable between shells or shell windows.  Get used to calling `setup-environment` whenever (if) you start a new shell.  Or, keep a long running shell that is setup once.

## Adding the ../sources/meta-ntrip layer to your build environment

**(ensure you are in your build environment.  That means you have done setup-environment in your shell.)**

 1. copy this (`meta-ntrip`) folder to `$YOCTO_DIR/sources/meta-ntrip`
 2. from `$YOCTO_DIR/$YOCTO_ENV`, run `bitbake-layers add-layer ../sources/meta-ntrip`

### Quick Start

```
make environment-update
```

## Building

**(ensure you are in your build environment.  That means you have done setup-environment in your shell.)**

 1. from `$YOCTO_DIR/$YOCTO_ENV`, run `bitbake ntrip-application`
 2. from `$YOCTO_DIR/$YOCTO_ENV`, run `bitbake ntrip-swu`

Then there will be a file with a `.swu` extension built at:
`$YOCTO_DIR/$YOCTO_ENV/tmp/deploy/images/$MACHINE/ntrip-swu-$MACHINE-YYYYMMDDHHMMSS.swu`.  Where:

```
MACHINE=var-som-mx6-ornl
```

You can upload that file to your device to update the application and its configuration.

## Configuring the application at runtime

You can also change parameters of the application after it is installed.
You will need to connect to a console and perform `make provision` in the `/usr/local/src/ntrip` folder:

```
make -C /usr/local/src/ntrip provision
```

## Patches

Please submit any pull requests against the `meta-ntrip` layer to https://github.com/uvdl/ntrip

