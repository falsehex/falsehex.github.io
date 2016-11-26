PacketZero README - 26 May 16
=============================

Website
=======
www.falsehex.com

Introduction
============
PacketZero is a 3D network monitor, displaying hosts and packet traffic. Features include support for multiple sensors (sensor0), analysis of packets to gather hostnames and services, configurable layout of subnetworks, recording/replaying of packet traffic, and the ability to filter packets by hosts, protocol or port.

sensor0 is a packet capture agent which reads and sends packet header information to PacketZero, locally or remotely. sensor0 also equates hostname to IP by reading DNS packets (UDP type A class IN standard query response). Multiple sensors can send information to multiple computers running PacketZero on the same subnet via broadcast.

Hardware Requirements - PacketZero
==================================
3-Button Scroll Mouse
OpenGL Support

Software Requirements
=====================
PacketZero requires Simple DirectMedia Layer 2.0 (SDL2).
  Mac OS X: Download https://www.libsdl.org/tmp/release/SDL2-2.0.4.dmg, put SDL2.framework in /Library/Frameworks/

sensor0 requires libpcap/WinPcap.

Compiling
=========
Linux: Install g++, SDL2 (dev), libpcap (dev), compile using "compile-packet0.sh" and "compile-sensor0.sh" scripts.
Mac OS X: Install Xcode, compile using "compile-packet0.sh" and "compile-sensor0.sh" scripts.
Windows (sensor0 only): Install Visual Studio Community and WinPcap Developer Pack.

Installation
============
Linux, Mac OS X:
  Put executables "packet0" and "sensor0" in /usr/local/bin/
  Put man pages "packet0.1" and "sensor0.1" in /usr/local/share/man/man1/
  These directories may have to be created.

Firewall configuration: By default, sensor0 talks to PacketZero via UDP port 6333.

Starting - sensor0
==================
Starting order does not matter, however if sensor0 is running and PacketZero is not, ICMP Port Unreachable (UDP port 6333) may be generated.

Linux, Mac OS X:

  sensor0 [-i <interface/file>] [-s <id>] [-h <destination>] [-u <port>] [-p] [-d]
    -i <interface> - Listen on interface (en0, eth1, ppp0, wlan0, etc.); or
       <file> - Read packets from pcap file.  Standard input is used if file is "-".
    -s <id> - Identify packets from a specific sensor when multiple exist (1-255, default 1).
    -h <destination> - PacketZero IP or broadcast address (default localhost).
    -u <port> - PacketZero UDP port (default 6333).
    -p - Enable promiscuous mode.
    -d - Run as daemon.

  Omit "-i <interface/file>" to display an Interface List for selection.
  Capturing packets requires you start sensor0 as root.
  View syslog to assist troubleshooting.

Windows:

  sensor0.exe [[[<id>] <destination>] <port>] [-p]
    <id> - Identify packets from a specific sensor when multiple exist (1-255, default 1).
    <destination> - PacketZero IP or broadcast address (default localhost).
    <port> - PacketZero UDP port (default 6333).
    -p - Enable promiscuous mode.

Data Files - PacketZero
=======================
Created in directory:
  Linux: ~/.packet0/
  Mac OS X: ~/Library/Application Support/PacketZero/

Files:
  controls.txt - Controls
  packet0_prefs - Preferences
  0network_0nl - Network Layout On-Exit
  1network_0nl - Network Layout 1
  2network_0nl - Network Layout 2
  3network_0nl - Network Layout 3
  4network_0nl - Network Layout 4
  netpos.txt - CIDR Notation Net Position/Colour
  traffic_0pt - Packet Traffic Record
  tmp_packet0 - Temporary Data

Net Positions - PacketZero 
==========================
If a host is not a member of any net position entries, it is placed in the Grey Zone. If a host is a member of multiple net position entries, the first entry is used. Line format for net position entries is "pos net x-position y-position z-position colour", eg. "pos 123.123.123.123/32 10 0 -10 green".

Positions:
  Grey/Red - positive x-position
  Blue/Green - negative x-position
  Up - positive y-position
  Down - negative y-position
  Grey/Blue - positive z-position
  Red/Green - negative z-position

Colours:
  none (where multiple colours are used)
  default (grey)
  orange
  yellow
  fluro
  green
  mint
  aqua
  blue
  purple
  violet
  hold (place hosts in same position)

Start/Stop Local Sensor - PacketZero
====================================
If sudo is required to start/stop a local sensor, the user starting sensor0 must be in /etc/sudoers. The default command to stop a local sensor is "killall sensor0", which will kill all sensor0 processes. Add the following to /etc/sudoers, replacing <user> with the required username:

  <user> ALL=(root) NOPASSWD: /usr/local/bin/sensor0
  <user> ALL=(root) NOPASSWD: /usr/bin/killall

Controls - PacketZero 
=====================
Press H key in PacketZero to show controls.

Notes
=====
- Support only for IPv4.
- IP headers with options are ignored.
- Support for packets with optionless GRE or VLAN 802.1Q encapsulation.
- By default hosts are added to PacketZero from packet source IP address, activate Add Destination Hosts to also add from destination IP address.
- Anomalies are a new host or host service.
- Clicking a host cluster will cycle through selecting hosts within.
- Using the menu options to move/arrange a few thousand hosts may take a few minutes.

Reporting Bugs
==============
Report bugs to <falsehex@gmail.com>

Copyright 2006-2016 Del Castle
