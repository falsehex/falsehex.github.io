#!/usr/bin/env python

#  sensor0-sim.py - Version 0.1  01 Sep 15
#  PacketZero - 3D Network Monitor
#  Copyright 2006-2015 Del Castle

#  Usage: python sensor0-sim.py

import random, socket, struct, time

sensorID = 1
addrPacket0 = ("127.0.0.1", 6333)  # port 6333 used for sensor0-to-packet0 traffic
sockPacket0 = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
showProtocols = [1, 6, 17, 249]  # ICMP, TCP, UDP, ARP
print "Ctrl+C to Stop"
while 1:
  numProtocol = random.randint(0, 3)
  srcIP = (random.randint(1, 254) * 16777216) + 43200  # 192.168.0.0/24
  dstIP = (random.randint(1, 254) * 16777216) + 43200  # 192.168.0.0/24
  if srcIP != dstIP:
    srcPort = random.randint(1, 65535)
    dstPort = random.randint(1, 65535)
    numPackets = random.randint(1, 200)
    if numPackets > 50: numPackets = 1
    for cntPackets in range(0, numPackets):
      packetXtra = struct.pack("=c?BBBBBBIIIHHBB", chr(85), 0, 0, 0, 0, 0, 0, 0, 48, srcIP, dstIP, srcPort, dstPort, sensorID, showProtocols[numProtocol])
      sockPacket0.sendto(packetXtra, addrPacket0)
      packetXtra = struct.pack("=c?BBBBBBIIIHHBB", chr(85), 0, 0, 0, 0, 0, 0, 0, 48, dstIP, srcIP, dstPort, srcPort, sensorID, showProtocols[numProtocol])
      sockPacket0.sendto(packetXtra, addrPacket0)
      time.sleep(0.01)
