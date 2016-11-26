/* bluffer.cpp - Version 1.0.2  14 Sep 15
   Bluffer - Network Service Imitator
   Copyright 2010-2015 Del Castle

   Requires libpcap-dev, libnet1-dev

   Linux Compile: g++ -O2 -o bluffer bluffer.cpp -lpcap -lnet
*/

#include <arpa/nameser_compat.h>
#include <arpa/tftp.h>
#include <libnet.h>
#include <netinet/if_ether.h>
#include <netinet/ip_icmp.h>
#include <netinet/tcp.h>
#include <netinet/udp.h>
#include <pcap.h>
#include <sys/stat.h>
#include <time.h>

unsigned char cntError = 0;
pcap_t *pPcap;
libnet_t *pLnet;

void stopRun(int sig)
{
  if (sig) pcap_breakloop(pPcap);
}

void build_ethernet(unsigned char *dstmac, unsigned short type)
{
  libnet_autobuild_ethernet(dstmac,  //dest mac address
                            type,  //upper layer protocol
                            pLnet);  //create ethernet header
  if (libnet_write(pLnet) != -1) cntError = 0;  //write packet
  else if (++cntError == 10)  //10 write errors in succession
  {
    fprintf(stderr, "bluffer error: libnet_write() ipv4 failed- %s\n", libnet_geterror(pLnet));
    stopRun(SIGINT);
  } 
  libnet_clear_packet(pLnet);
}

void build_ipv4(unsigned char *dstmac, unsigned int srcip, unsigned int dstip, unsigned char protocol, unsigned short len)
{
  libnet_build_ipv4(LIBNET_IPV4_H + len,  //total len
                    1,  //tos
                    libnet_get_prand(LIBNET_PRu16),  //id
                    0,  //frag
                    64,  //ttl
                    protocol,  //protocol
                    0,  //checksum
                    srcip,  //source ip address
                    dstip,  //dest ip address
                    0,  //payload
                    0,  //payload size
                    pLnet,
                    0);  //create ipv4 header
  build_ethernet(dstmac, ETHERTYPE_IP);
}

//pcap_loop
void processPacket(u_char *u, const struct pcap_pkthdr *hdr, const u_char *pkt)
{
  time_t timeNow = time(0);
  char strTime[6], strIP[INET_ADDRSTRLEN];
  strftime(strTime, 6, "%H:%M", gmtime(&timeNow));
  ether_header *hdrEther = (ether_header *)pkt;
  if (ntohs(hdrEther->ether_type) == ETHERTYPE_ARP)
  {
    ether_arp *hdrARP = (ether_arp *)(pkt + LIBNET_ETH_H);
    if (ntohs(hdrARP->ea_hdr.ar_op) != ARPOP_REQUEST) return;
    if (!memcmp(hdrARP->arp_spa, hdrARP->arp_tpa, 4)) return;
    fprintf(stdout, "**  %s ARP REQUEST %s\n", strTime, inet_ntop(AF_INET, hdrARP->arp_tpa, strIP, INET_ADDRSTRLEN));
    libnet_autobuild_arp(ARPOP_REPLY,  //operation type
                         (unsigned char *)libnet_get_hwaddr(pLnet),  //source hardware address
                         hdrARP->arp_tpa,  //source protocol address
                         hdrARP->arp_sha,  //dest hardware address
                         hdrARP->arp_spa,  //dest protocol address
                         pLnet);  //create arp header
    build_ethernet(hdrEther->ether_shost, ETHERTYPE_ARP);
    fflush(stdout);
    return;
  }
  else if (ntohs(hdrEther->ether_type) != ETHERTYPE_IP) return;
  iphdr *hdrIP = (iphdr *)(pkt + LIBNET_ETH_H);
  if (hdrIP->tos) return;
  if (hdrIP->version != 4) return;  //not IPv4
  if (hdrIP->ihl != 5) return;  //IPv4 options check
  unsigned short szData = 0;
  unsigned int szPayload = 0;
  char strPayload[1460] = "";  //1518 - ETH 18 - IP 20 - TCP 20
  if (hdrIP->protocol == IPPROTO_ICMP)
  {
    icmphdr *hdrICMP = (icmphdr *)(pkt + LIBNET_ETH_H + LIBNET_IPV4_H);
    if (hdrICMP->type == ICMP_ECHO)
    {
      fprintf(stdout, "**  %s PING ECHO DEST %s\n", strTime, inet_ntop(AF_INET, &hdrIP->daddr, strIP, INET_ADDRSTRLEN));
      szData = ntohs(hdrIP->tot_len) - (LIBNET_IPV4_H + LIBNET_ICMPV4_ECHO_H);
      if (szData)
      {
        memcpy(strPayload, (char *)(pkt + LIBNET_ETH_H + LIBNET_IPV4_H + LIBNET_ICMPV4_ECHO_H), szData);
        libnet_build_icmpv4_echo(ICMP_ECHOREPLY,  //type
                                 0,  //code
                                 0,  //checksum
                                 ntohs(hdrICMP->un.echo.id),  //id
                                 ntohs(hdrICMP->un.echo.sequence), //seq
                                 (unsigned char *)strPayload,  //payload
                                 szData,  //payload size
                                 pLnet,
                                 0);  //create icmp packet
        build_ipv4(hdrEther->ether_shost, hdrIP->daddr, hdrIP->saddr, hdrIP->protocol, LIBNET_ICMPV4_ECHO_H + szData);
      }
    }
    else fprintf(stdout, "**  %s PING TYPE %hhu DEST %s\n", strTime, hdrICMP->type, inet_ntop(AF_INET, &hdrIP->daddr, strIP, INET_ADDRSTRLEN));
  }
  else if (hdrIP->protocol == IPPROTO_TCP)
  {
    tcphdr *hdrTCP = (tcphdr *)(pkt + LIBNET_ETH_H + LIBNET_IPV4_H);
    unsigned char flagsTCP = TH_ACK;
    unsigned int ackTCP = ntohl(hdrTCP->seq) + 1;
    szData = ntohs(hdrIP->tot_len) - (LIBNET_IPV4_H + (hdrTCP->doff * 4));
    if (hdrTCP->syn)
    {
      fprintf(stdout, "**  %s TCP SOCKET DEST %s PORT %hu\n", strTime, inet_ntop(AF_INET, &hdrIP->daddr, strIP, INET_ADDRSTRLEN), ntohs(hdrTCP->dest));
      flagsTCP |= TH_SYN;
    }
    else if (hdrTCP->fin) flagsTCP |= TH_FIN;
    else if (hdrTCP->rst) return;
    else if (hdrTCP->ack && !szData)
    {
      flagsTCP |= TH_PUSH;
      ackTCP -= 1;
      if (ntohs(hdrTCP->dest) == 21) sprintf(strPayload, "220 Microsoft FTP Service\r\n");
      else if ((ntohs(hdrTCP->dest) == 25) || (ntohs(hdrTCP->dest) == 465) || (ntohs(hdrTCP->dest) == 587)) sprintf(strPayload, "220 mail.microsoft.com Microsoft SMTP MAIL Service\r\n");
      else if ((ntohs(hdrTCP->dest) == 109) || (ntohs(hdrTCP->dest) == 110) || (ntohs(hdrTCP->dest) == 995)) sprintf(strPayload, "+OK POP3 server ready\r\n");
      else if ((ntohs(hdrTCP->dest) == 143) || (ntohs(hdrTCP->dest) == 220) || (ntohs(hdrTCP->dest) == 993)) sprintf(strPayload, "* OK IMAP server ready\r\n");
      else return;
    }
    if (szData)
    {
      char strData[szData + 1], strDate[32];
      strncpy(strData, (char *)(pkt + LIBNET_ETH_H + LIBNET_IPV4_H + (hdrTCP->doff * 4)), szData);
      strData[szData] = '\0';
      strftime(strDate, 32, "%a, %d %b %Y %H:%M:%S %Z", gmtime(&timeNow));
      if (strstr(strData, "/wpad.dat HTTP/1."))
      {
        fprintf(stdout, "*** HTTP REQUEST:\n%s\n\n", strData);
        inet_ntop(AF_INET, &hdrIP->daddr, strIP, INET_ADDRSTRLEN);
        sprintf(strPayload, "HTTP/1.0 200 OK\r\nServer: Microsoft-IIS/4.0\r\nDate: %s\r\nContent-Type: text/javascript\r\nConnection: close\r\nContent-Length: %u\r\n\r\nfunction FindProxyForURL(url, host) { return \"PROXY %s:80\"; }\n", strDate, (unsigned int)strlen(strIP) + 60, strIP);
        flagsTCP |= TH_PUSH | TH_FIN;
      }
      else if (strstr(strData, " HTTP/1."))
      {
        fprintf(stdout, "*** HTTP REQUEST:\n%s\n\n", strData);
        char *pEnd = strtok(strData, " "), *pFilename;
        struct stat statFile;
        pEnd = strtok(NULL, " ");
        pFilename = strrchr(pEnd, '/');
        if (!stat(++pFilename, &statFile))  //++ remove /
        {
          size_t szFile;
          FILE *fileDownload;
          if (statFile.st_size > 1296) statFile.st_size = 1296;  //1518 - ETH 18 - IP 20 - TCP 20 - 164
          sprintf(strPayload, "HTTP/1.0 200 OK\r\nServer: Microsoft-IIS/4.0\r\nDate: %s\r\nContent-Type: application/octet-stream\r\nConnection: close\r\nContent-Length: %ld\r\n\r\n", strDate, statFile.st_size);
          szPayload = strlen(strPayload);  //max 164
          fileDownload = fopen(pFilename, "rb");
          szFile = fread(strPayload + szPayload, 1, statFile.st_size, fileDownload);
          fclose(fileDownload);
          szPayload += szFile;
        }
        else sprintf(strPayload, "HTTP/1.0 200 OK\r\nServer: Microsoft-IIS/4.0\r\nDate: %s\r\nContent-Type: text/html\r\nConnection: close\r\nContent-Length: 91\r\n\r\n<html><head><title>Under Construction</title></head><body>Under Construction</body></html>\n", strDate);
        flagsTCP |= TH_PUSH | TH_FIN;
      }
      else if (ntohs(hdrTCP->dest) == 21)
      {
        if (strstr(strData, "USER ") == strData) fprintf(stdout, "*** FTP CONNECTION:\n");
        if ((strstr(strData, "USER ") == strData) || (strstr(strData, "PASS ") == strData) || (strstr(strData, "ACCT ") == strData))
        {
          sprintf(strPayload, "230 User logged in, proceed.\r\n");
          flagsTCP |= TH_PUSH;
        }
        else if ((strstr(strData, "CWD ") == strData) || (strstr(strData, "SMNT ") == strData) || (strstr(strData, "RNTO ") == strData) || (strstr(strData, "DELE ") == strData) || (strstr(strData, "RMD ") == strData))
        {
          sprintf(strPayload, "250 Requested file action okay, completed.\r\n");
          flagsTCP |= TH_PUSH;
        }
        else if ((strstr(strData, "CDUP\r\n") == strData) || (strstr(strData, "PORT ") == strData) || (strstr(strData, "MODE ") == strData) || (strstr(strData, "TYPE ") == strData) || (strstr(strData, "STRU ") == strData) || (strstr(strData, "ALLO ") == strData) || (strstr(strData, "SITE ") == strData) || (strstr(strData, "NOOP\r\n") == strData))
        {
          sprintf(strPayload, "200 Command okay.\r\n");
          flagsTCP |= TH_PUSH;
        }
        else if ((strstr(strData, "REIN\r\n") == strData) || (strstr(strData, "PASV\r\n") == strData) || (strstr(strData, "REST ") == strData) || (strstr(strData, "RNFR ") == strData) || (strstr(strData, "MKD ") == strData) || (strstr(strData, "PWD\r\n") == strData) || (strstr(strData, "ABOR\r\n") == strData) || (strstr(strData, "SYST\r\n") == strData) || (strstr(strData, "STAT") == strData) || (strstr(strData, "HELP") == strData))
        {
          sprintf(strPayload, "502 Command not implemented.\r\n");
          flagsTCP |= TH_PUSH;
        }
        else if ((strstr(strData, "STOR ") == strData) || (strstr(strData, "STOU\r\n") == strData) || (strstr(strData, "RETR ") == strData) || (strstr(strData, "LIST") == strData) || (strstr(strData, "NLST") == strData) || (strstr(strData, "APPE ") == strData))
        {
          sprintf(strPayload, "425 Can't open data connection.\r\n");
          flagsTCP |= TH_PUSH;
        }
        else if (strstr(strData, "QUIT\r\n") == strData)
        {
          sprintf(strPayload, "221 Service closing control connection.\r\n");
          flagsTCP |= TH_PUSH;
        }
        fprintf(stdout, "%s\n\n", strData);
      }
      else if ((ntohs(hdrTCP->dest) == 25) || (ntohs(hdrTCP->dest) == 465) || (ntohs(hdrTCP->dest) == 587))
      {
        if (strstr(strData, "HELO ") == strData)
        {
          fprintf(stdout, "*** SMTP CONNECTION:\n");
          sprintf(strPayload, "220 mail.microsoft.com\r\n");
          flagsTCP |= TH_PUSH;
        }
        else if (strstr(strData, "EHLO ") == strData)
        {
          fprintf(stdout, "*** SMTP CONNECTION:\n");
          sprintf(strPayload, "250-mail.microsoft.com\r\n250-SIZE 20480000\r\n250 DSN\r\n");
          flagsTCP |= TH_PUSH;
        }
        else if (strstr(strData, "DATA\r\n") == strData)
        {
          sprintf(strPayload, "354 End data with <CR><LF>.<CR><LF>\r\n");
          flagsTCP |= TH_PUSH;
        }
        else if (strstr(strData, "HELP") == strData)
        {
          sprintf(strPayload, "214 Server\r\n");
          flagsTCP |= TH_PUSH;
        }
        else if (strstr(strData, "QUIT\r\n") == strData)
        {
          sprintf(strPayload, "221 Bye\r\n");
          flagsTCP |= TH_PUSH;
        }
        else if ((strstr(strData, "MAIL FROM:") == strData) || (strstr(strData, "RCPT TO:") == strData) || (strstr(strData, "\r\n.\r\n") == strData) || (strstr(strData, "RSET\r\n") == strData) || (strstr(strData, "SEND FROM:") == strData) || (strstr(strData, "SOML FROM:") == strData) || (strstr(strData, "SAML FROM:") == strData) || (strstr(strData, "VRFY ") == strData) || (strstr(strData, "EXPN ") == strData) || (strstr(strData, "NOOP\r\n") == strData) || (strstr(strData, "TURN\r\n") == strData))
        {
          sprintf(strPayload, "250 OK\r\n");
          flagsTCP |= TH_PUSH;
        }
        fprintf(stdout, "%s\n\n", strData);
      }
      else if ((ntohs(hdrTCP->dest) == 109) || (ntohs(hdrTCP->dest) == 110) || (ntohs(hdrTCP->dest) == 995))
      {
        if ((strstr(strData, "APOP ") == strData) || (strstr(strData, "USER ") == strData))
        {
          fprintf(stdout, "*** POP3 CONNECTION:\n");
          sprintf(strPayload, "+OK server ready\r\n");
          flagsTCP |= TH_PUSH;
        }
        else if ((strstr(strData, "PASS ") == strData) || (strstr(strData, "STAT\r\n") == strData) || (strstr(strData, "LIST") == strData) || (strstr(strData, "RETR ") == strData) || (strstr(strData, "DELE ") == strData) || (strstr(strData, "NOOP\r\n") == strData) || (strstr(strData, "LAST\r\n") == strData) || (strstr(strData, "RSET\r\n") == strData) || (strstr(strData, "QUIT\r\n") == strData))
        {
          sprintf(strPayload, "+OK 0 0\r\n");
          flagsTCP |= TH_PUSH;
        }
        fprintf(stdout, "%s\n\n", strData);
      }
      else if ((ntohs(hdrTCP->dest) == 143) || (ntohs(hdrTCP->dest) == 220) || (ntohs(hdrTCP->dest) == 993))
      {
        char strTag[33], strCommand[33];
        sscanf(strData, "%32s %32s", strTag, strCommand);
        if ((strstr(strCommand, "CAPABILITY") == strCommand) || (strstr(strCommand, "LOGIN") == strCommand) || (strstr(strCommand, "AUTHENTICATE") == strCommand)) fprintf(stdout, "*** IMAP CONNECTION:\n");
        sprintf(strPayload, "%s OK %s server ready\r\n", strTag, strCommand);
        flagsTCP |= TH_PUSH;
        fprintf(stdout, "%s\n\n", strData);
      }
      ackTCP += szData - 1;
    }
    if (!szPayload) szPayload = strlen(strPayload);
    libnet_build_tcp(ntohs(hdrTCP->dest),  //source port
                     ntohs(hdrTCP->source),  //dest port
                     (hdrTCP->syn ? libnet_get_prand(LIBNET_PRu32) : ntohl(hdrTCP->ack_seq)),  //seq
                     ackTCP,  //ack
                     flagsTCP, //flags
                     8760,  //window
                     0,  //checksum
                     0,  //urg
                     LIBNET_TCP_H + szPayload,  //len
                     (szPayload ? (unsigned char *)strPayload : 0),  //payload
                     szPayload,  //payload size
                     pLnet,
                     0);  //create tcp packet
    build_ipv4(hdrEther->ether_shost, hdrIP->daddr, hdrIP->saddr, hdrIP->protocol, LIBNET_TCP_H + szPayload);
  }
  else if ((hdrIP->protocol == IPPROTO_UDP) && (ntohs(hdrIP->tot_len) - (LIBNET_IPV4_H + LIBNET_UDP_H)))
  {
    udphdr *hdrUDP = (udphdr *)(pkt + LIBNET_ETH_H + LIBNET_IPV4_H);
    fprintf(stdout, "**  %s UDP SOCKET DEST %s PORT %hu\n", strTime, inet_ntop(AF_INET, &hdrIP->daddr, strIP, INET_ADDRSTRLEN), ntohs(hdrUDP->dest));
    if (ntohs(hdrUDP->dest) == 53)
    {
      HEADER *hdrDNS = (HEADER *)(pkt + LIBNET_ETH_H + LIBNET_IPV4_H + LIBNET_UDP_H);
      if (!hdrDNS->qr && !hdrDNS->opcode && !hdrDNS->rcode && (ntohs(hdrDNS->qdcount) == 1))
      {
        fprintf(stdout, "*** DNS REQUEST:\n");
        char *pQuery = (char *)(pkt + LIBNET_ETH_H + LIBNET_IPV4_H + LIBNET_UDP_H + LIBNET_DNS_H), *pName = pQuery;
        unsigned char cntLabel;
        while (*pName)
        {
          for (cntLabel = *pName; cntLabel; cntLabel--)
          {
            pName++;
            fprintf(stdout, "%c", *pName);
          }
          pName++;
          if (*pName) fprintf(stdout, ".");
        }
        fprintf(stdout, "\n\n");
        strncpy(strPayload, pQuery, 1439);  //1460 - (17 + 4)
        memcpy(strPayload + strlen(pQuery), "\x00\x00\x01\x00\x01\xc0\x0c\x00\x01\x00\x01\x00\x00\x00\x04\x00\x04", 17);
        memcpy(strPayload + strlen(pQuery) + 17, &hdrIP->daddr, 4);
        libnet_build_dnsv4(LIBNET_UDP_DNSV4_H,
                           ntohs(hdrDNS->id),  //id
                           0x8000,  //flags
                           1,  //num_q
                           1,  //num_anws_rr
                           0,  //num_auth_rr
                           0,  //num_addi_rr
                           (unsigned char *)strPayload,  //payload
                           strlen(pQuery) + 21,  //payload size
                           pLnet,
                           0);  //create dns packet
        szData = LIBNET_DNS_H + strlen(pQuery) + 21;  //17 + 4
      }
    }
    else if (ntohs(hdrUDP->dest) == 67)
    {
      libnet_dhcpv4_hdr *hdrDHCP = (libnet_dhcpv4_hdr *)(pkt + LIBNET_ETH_H + LIBNET_IPV4_H + LIBNET_UDP_H);
      if ((hdrDHCP->dhcp_opcode == LIBNET_DHCP_REQUEST) && (ntohl(hdrDHCP->dhcp_magic) == DHCP_MAGIC) && hdrDHCP->dhcp_cip)
      {
        unsigned int *pInform = (unsigned int *)(pkt + LIBNET_ETH_H + LIBNET_IPV4_H + LIBNET_UDP_H + LIBNET_DHCPV4_H - 1);
        if (ntohl(*pInform) == 0x63350108)
        {
          fprintf(stdout, "*** DHCP INFORM REQUEST\n\n");
          hdrIP->daddr = libnet_get_ipaddr4(pLnet);
          memcpy(strPayload, "\x35\x01\x05\x36\x04", 5);
          memcpy(strPayload + 5, &hdrIP->daddr, 4);
          memcpy(strPayload + 9, "\xfc\x20", 2);
          memcpy(strPayload + 11, "http://wpad.microsoft.com/wpad.dat", 34);
          memcpy(strPayload + 45, "\xff\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00", 17);
          libnet_build_dhcpv4(LIBNET_DHCP_REPLY,  //opcode
                              hdrDHCP->dhcp_htype,  //htype
                              hdrDHCP->dhcp_hlen,  //hlen
                              0,  //hopcount
                              ntohl(hdrDHCP->dhcp_xid),  //xid
                              0,  //secs
                              0,  //flags
                              ntohl(hdrDHCP->dhcp_cip),  //client ip address
                              0,  //your ip address
                              0,  //server's ip address
                              0,  //gateway ip address
                              hdrDHCP->dhcp_chaddr,  //client hardware address
                              0,  //server host
                              0,  //boot file
                              (unsigned char *)strPayload,  //payload
                              62,  //payload size
                              pLnet,
                              0);  //create dhcp packet
          szData = LIBNET_DHCPV4_H + 62;  //5 + 4 + 2 + 34 + 17
        }
      }
    }
    else if (ntohs(hdrUDP->dest) == 69)
    {
      tftphdr *hdrTFTP = (tftphdr *)(pkt + LIBNET_ETH_H + LIBNET_IPV4_H + LIBNET_UDP_H);
      if (ntohs(hdrTFTP->th_opcode) == RRQ) fprintf(stdout, "*** TFTP DOWNLOAD FILE:\n%s\n\n", (char *)hdrTFTP + 2);
      else if (ntohs(hdrTFTP->th_opcode) == WRQ) fprintf(stdout, "*** TFTP UPLOAD FILE:\n%s\n\n", (char *)hdrTFTP + 2);
    }
    else if (ntohs(hdrUDP->dest) == 137)
    {
      HEADER *hdrNBNS = (HEADER *)(pkt + LIBNET_ETH_H + LIBNET_IPV4_H + LIBNET_UDP_H);
      if (!hdrNBNS->qr && !hdrNBNS->opcode && !hdrNBNS->rcode && (ntohs(hdrNBNS->qdcount) == 1))
      {
        fprintf(stdout, "*** NBNS REQUEST:\n");
        char chName, *pQuery = (char *)(pkt + LIBNET_ETH_H + LIBNET_IPV4_H + LIBNET_UDP_H + LIBNET_DNS_H), *pName = pQuery + 1;
        while (*pName)
        {
          chName = (*pName - 'A') << 4;
          pName++;
          fprintf(stdout, "%c", chName + (*pName - 'A'));
          pName++;
        }
        fprintf(stdout, "\n\n");
        hdrIP->daddr = libnet_get_ipaddr4(pLnet);
        strncpy(strPayload, pQuery, 1443);  //1460 - (13 + 4)
        memcpy(strPayload + strlen(pQuery), "\x00\x00\x20\x00\x01\x00\x00\x00\x00\x00\x06\x60\x00", 13);
        memcpy(strPayload + strlen(pQuery) + 13, &hdrIP->daddr, 4);
        libnet_build_dnsv4(LIBNET_UDP_DNSV4_H,
                           ntohs(hdrNBNS->id),  //id
                           0x8400,  //flags
                           0,  //num_q
                           1,  //num_anws_rr
                           0,  //num_auth_rr
                           0,  //num_addi_rr
                           (unsigned char *)strPayload,  //payload
                           strlen(pQuery) + 17,  //payload size
                           pLnet,
                           0);  //create dns packet
        szData = LIBNET_DNS_H + strlen(pQuery) + 17;  //13 + 4
      }
    }
    if (szData)
    {
      libnet_build_udp(ntohs(hdrUDP->dest),  //source port
                       ntohs(hdrUDP->source),  //dest port
                       LIBNET_UDP_H + szData,  //len
                       0,  //checksum
                       0,  //payload
                       0,  //payload size
                       pLnet,
                       0);  //create udp header
      build_ipv4(hdrEther->ether_shost, hdrIP->daddr, hdrIP->saddr, hdrIP->protocol, LIBNET_UDP_H + szData);
    }
  }
  fflush(stdout);
}

int main()
{
  if (system("iptables -F;iptables -P INPUT DROP")) fprintf(stderr, "bluffer error: iptables drop failed\n");
  char strInterface[] = "eth0", errorBuffer[PCAP_ERRBUF_SIZE];
  if (!(pPcap = pcap_open_live(strInterface, 1518, 0, 20, errorBuffer)))
  {
    fprintf(stderr, "bluffer error: pcap_open_live() failed- %s, are you root?\n", errorBuffer);
    return 1;
  }
  if (!(pLnet = libnet_init(LIBNET_LINK, strInterface, errorBuffer)))  //write packets at layer 2
  {
    fprintf(stderr, "bluffer error: libnet_init() failed- %s, are you root?\n", errorBuffer);
    return 1;
  }
  if (libnet_seed_prand(pLnet) == -1)  //seed random number generator
  {
    fprintf(stderr, "bluffer error: libnet_seed_prand() failed\n");
    libnet_destroy(pLnet);
    return 1;
  }
  signal(SIGINT, stopRun);  //capture ctrl+c
  signal(SIGTERM, stopRun);  //capture kill
  pcap_loop(pPcap, -1, processPacket, 0);
  libnet_destroy(pLnet);
  pcap_close(pPcap);
  if (system("iptables -P INPUT ACCEPT")) fprintf(stderr, "bluffer error: iptables accept failed\n");
  return 0;
}
