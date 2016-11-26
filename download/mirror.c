/* mirror.c - Version 1.0.1  28 Aug 15
   Mirror - Packet Traffic Interface Mirror
   Copyright 2008-2015 Del Castle

   Mirror copies packet traffic from one interface to another.

   Linux Compile: gcc -O2 -o mirror mirror.c

   Usage: mirror <interface 1> <interface 2> [-d]
            <interface 1/2> - Receive/Send interface.
            -d - Run as daemon.
*/

#include <net/if.h>
#include <netinet/if_ether.h>
#include <netinet/in.h>
#include <netpacket/packet.h>
#include <signal.h>
#include <stdio.h>
#include <string.h>
#include <sys/ioctl.h>
#include <sys/stat.h>
#include <unistd.h>

int goRun = 1;

void stopRun(int sig)
{
  if (sig) goRun = 0;
}

int main(int argc, char *argv[])
{
  int goDaemon = 0;
  if (argc > 1)
  {
    if (!strcmp(argv[argc - 1], "-d"))
    {
      goDaemon = 1;
      argc--;
    }
  }
  if (argc != 3)
  {
    fprintf(stderr, "Mirror 1.0.1 usage: %s <interface 1> <interface 2> [-d]\n"
      "  <interface 1/2> : receive/send interface\n"
      "  -d : run as daemon\n"
      "Mirror copies packet traffic from one interface to another\n", argv[0]);
    return 1;
  }
  if (goDaemon)
  {
    pid_t processId = fork();
    if (processId == -1)
    {
      fprintf(stderr, "mirror error: fork() failed\n");
      return 1;
    }
    if (processId > 0) return 0;
    pid_t sessionId = setsid();
    if (sessionId == -1)
    {
      fprintf(stderr, "mirror error: setsid() failed\n");
      return 1;
    }
    umask(0);
  }
  int sockRecv, sockSend;
  if ((sockRecv = socket(PF_PACKET, SOCK_RAW, htons(ETH_P_ALL))) == -1)
  {
    fprintf(stderr, "mirror error: recv socket create failed, are you root?\n");
    return 1;
  }
  struct ifreq ifaceReq;
  strncpy(ifaceReq.ifr_name, argv[1], IFNAMSIZ);
  ifaceReq.ifr_name[IFNAMSIZ - 1] = '\0';
  if (ioctl(sockRecv, SIOCGIFINDEX, &ifaceReq) == -1)
  {
    fprintf(stderr, "mirror error: recv socket interface index failed\n");
    close(sockRecv);
    return 1;
  }
  struct sockaddr_ll addrRecv, addrSend;
  addrRecv.sll_family = AF_PACKET;
  addrRecv.sll_protocol = htons(ETH_P_ALL);
  addrRecv.sll_ifindex = ifaceReq.ifr_ifindex;
  if (bind(sockRecv, (struct sockaddr*)&addrRecv, sizeof(struct sockaddr_ll)) == -1)
  {
    fprintf(stderr, "mirror error: recv socket bind failed\n");
    close(sockRecv);
    return 1;
  }
  if ((sockSend = socket(PF_PACKET, SOCK_RAW, htons(ETH_P_ALL))) == -1)
  {
    fprintf(stderr, "mirror error: send socket create failed\n");
    close(sockRecv);
    return 1;
  }
  strncpy(ifaceReq.ifr_name, argv[2], IFNAMSIZ);
  ifaceReq.ifr_name[IFNAMSIZ - 1] = '\0';
  if (ioctl(sockSend, SIOCGIFINDEX, &ifaceReq) == -1)
  {
    fprintf(stderr, "mirror error: send socket interface index failed\n");
    close(sockRecv);
    close(sockSend);
    return 1;
  }
  addrSend.sll_family = AF_PACKET;
  addrSend.sll_protocol = htons(ETH_P_ALL);
  addrSend.sll_ifindex = ifaceReq.ifr_ifindex;
  if (bind(sockSend, (struct sockaddr*)&addrSend, sizeof(struct sockaddr_ll)) == -1)
  {
    fprintf(stderr, "mirror error: send socket bind failed\n");
    close(sockRecv);
    close(sockSend);
    return 1;
  }
  int szRecv;
  char packetBuffer[1500];
  signal(SIGINT, stopRun);  //capture ctrl+c
  signal(SIGTERM, stopRun);  //capture kill
  while (goRun)
  {
    if ((szRecv = recv(sockRecv, packetBuffer, 1500, 0)) == -1)
    {
      fprintf(stderr, "mirror error: recv packet failed\n");
      close(sockRecv);
      close(sockSend);
      return 1;
    }
    else if (send(sockSend, packetBuffer, szRecv, 0) != szRecv)
    {
      fprintf(stderr, "mirror error: send packet failed\n");
      close(sockRecv);
      close(sockSend);
      return 1;
    }
  }
  close(sockRecv);
  close(sockSend);
  return 0;
}
