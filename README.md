# ntrip

Code for managing Networked Transport of RTCM via Internet Protocol

## Features

 1. Static IP for RJ45 (ethernet) network - input as manufacturing step.  `172.20.x.y/16`.
 2. Use a proxy to/from UART to Pixhawk and `udp://172.20.255.255:14550`.

## Setup
To configure the software, execute the following commands:
```
make dependencies
make install
make provision
```

This can be done on a variety supported machines and operating systems that are Debian-based (Debian, Ubuntu, etc.) and which use `systemd` as the init program.  The commands are typically called in the above order (required for first time setup), but afterward can be done in any order desired or a-la-carte.

### `make dependencies`
This ensures that the operating system has the necessary libraries, programs and configurations needed to operate the software.  It uses the system package manager or pulls source code and compiles it as necessary and appropriate.  It is via this command that the operating system is updated for security patches as needed.

### `make install`
This causes the needed services and programs to be added to the system so that they will execute upon power on of the system.  The philosophy of the software is that all code and configurations be part of the system.  The files in this repository only exist to manipulate and configure the system, but otherwise are not a necessary part.  This means, for example, that an external device could hold this code, setup the system and then be removed.

You would use this command whenever you wanted to apply any new feature that was provided to you.

### `make provision`
This causes all the settings to be inspected and interactively changed.  Typically, this command is executed by the factory to setup the various configurations needed to operate the software.

## Services
The following services will be configured to execute upon system startup.

### gpsd
The GPS daemon.  This is a service that interfaces to GPS devices and provides local access to location.

### mavproxy
The program to connect a UDP port to the autopilot.  The program connects UDP packets to/from the autopilot.  It also handles the conversion of RTCM data into a format that can be sent to the GPS for location correction.

### ntpd
A program to keep local system time synchronized.  **(currently, the program is configured to interpret the pulse-per-second signal available on PixC3/PixC4 hardware.**

## References
* [MAVProxy PR#408](https://github.com/ArduPilot/MAVProxy/pull/408)
* [Diagnosing injected rtcm messages from MAVProxy to Ardurover](https://discuss.ardupilot.org/t/diagnosing-injected-rtcm-messages-from-mavproxy-to-ardurover/45385)
* [Ntrip working at all?](https://discuss.ardupilot.org/t/ntrip-working-at-all/51516)

