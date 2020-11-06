#!/usr/bin/perl

#  laconic.pl - Version 1.0.0  07 Nov 20
#  Laconic - Simple HTTP Server
#  Copyright 2020 Del Castle
#
#  Installation:
#    cp laconic.pl /usr/local/bin/
#    useradd -r -s /usr/sbin/nologin www
#    touch /var/log/http.log
#    chown www:www /usr/local/bin/laconic.pl /var/log/http.log
#    chmod 700 /usr/local/bin/laconic.pl
#    chmod 644 /var/log/http.log
#    Add to /etc/crontab: * *  * * *  www  ps -ef | grep laconic.pl | grep -v grep >/dev/null || laconic.pl >/dev/null 2>&1 &
#    Port forward 80 to 8123 on firewall

use strict;
use warnings;
use threads;
use Fcntl;
use IO::Socket::INET;

my $strKnock = 'itsme';  #code word to open firewall
my @txtDays = qw(Sun Mon Tue Wed Thu Fri Sat Sun);
my @txtMonths = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);
my %valMonths = qw(january 1 february 2 march 3 april 4 may 5 june 6 july 7 august 8 september 9 october 10 november 11 december 12);

#listening socket to receive request
my $sockListen = IO::Socket::INET->new(LocalPort => 8123,
                                       Proto => 'tcp',
                                       Listen => 100,
                                       ReuseAddr => 1) or die "listen socket error\n";

#capture kill to exit safely
$SIG{INT} = sub { close($sockListen); };
$SIG{TERM} = sub { close($sockListen); };

#process request
sub processReq
{
  my $sockClient = shift;  #client socket
  my $flagClient = fcntl($sockClient, F_GETFL, 0);
  fcntl($sockClient, F_SETFL, $flagClient | O_NONBLOCK);  #make client socket non-blocking

  my $timeOut = 3;  #socket timeout
  my $strLine;  #read line
  my $strHTML = '';  #server response
  my ($strMethod, $strURL, $strHost, $strReferer, $strAgent) = ('', '', '-', '-', '-');  #client request fields
  my ($valSec, $valMin, $valHour, $valMday, $valMon, $valYear, $valWday, $valYday, $valIsdst) = gmtime();  #current UTC time

  while ($timeOut)
  {
    while ($strLine = <$sockClient>)  #read line from client socket
    {
      $timeOut = 0;
      if ($strLine =~ /^GET\s\/\?year=(\d{4})&month=([a-z]+)&day=(\d{1,2})&eid=(\d+)\sHTTP/)  #smurt email request
      {
        my ($dateYear, $dateMonth, $dateDay, $idMail) = ($1, $2, $3, $4);
        my $fileMail = sprintf("/var/log/mail/%d/%02d/%02d/mail-%d.txt", $dateYear, $valMonths{$dateMonth}, $dateDay, $idMail);
        open(INMAIL, "<", $fileMail);
        read INMAIL, $strHTML, -s INMAIL;  #read full file
        close(INMAIL);
	$strHTML =~ s/&/&amp;/sg;  #encode reserved &
	$strHTML =~ s/</&lt;/sg;  #encode reserved <
	$strHTML =~ s/>/&gt;/sg;  #encode reserved >
	$strHTML = "<html><head><title>Email - $idMail</title></head><body><pre>$strHTML</pre></body></html>";
      }
      elsif ($strLine =~ /^(GET|HEAD|POST|PUT|DELETE|CONNECT|OPTIONS|TRACE|PATCH)\s([^\s]+)\sHTTP/)
      {
        $strMethod = $1;
        $strURL = $2;
        $strURL =~ s/(")/sprintf("%%%02X", ord($1))/seg;  #encode quotes
        if ($strURL eq "/$strKnock")  #firewall open request
        {
          my $iptClient = 'INPUT -i enp1s0 -p tcp -s ' . $sockClient->peerhost() . ' --dport 8000 -m state --state NEW -j ACCEPT';  #iptables allow client to splunk web
          system("sudo iptables -C $iptClient || sudo iptables -A $iptClient");  #check if rule exists first
          $strHTML = '<html><head><title>&pi;</title></head><body><h3>&pi;</h3></body></html>';
        }
	else
	{
          $strHTML = '<html><head><title>Under Construction</title></head><body><p>Website Currently Unavailable - Under Construction!</p></body></html>';
        }
      }
      elsif ($strLine =~ /^Host:\s(.+)\r\n$/)
      {
        $strHost = $1;
        $strHost =~ s/(")/sprintf("%%%02X", ord($1))/seg;  #encode quotes
      }
      elsif ($strLine =~ /^Referer:\s(.+)\r\n$/)
      {
        $strReferer = $1;
        $strReferer =~ s/(")/sprintf("%%%02X", ord($1))/seg;  #encode quotes
      }
      elsif ($strLine =~ /^User-Agent:\s(.+)\r\n$/)
      {
        $strAgent = $1;
        $strAgent =~ s/(")/sprintf("%%%02X", ord($1))/seg;  #encode quotes
      }
    }
    if ($timeOut)
    {
      sleep(1);
      $timeOut--;
    }
  }

  if ($strHTML ne '')  #server response
  {
    my $strSdate = sprintf("%s, %02d %s 20%02d %02d:%02d:%02d GMT", $txtDays[$valWday], $valMday, $txtMonths[$valMon], $valYear - 100, $valHour, $valMin, $valSec);  #server date
    print $sockClient "HTTP/1.1 200 OK\r\n";
    print $sockClient "Date: $strSdate\r\n";
    print $sockClient "Server: Laconic\r\n";
    print $sockClient "Last-Modified: $strSdate\r\n";
    print $sockClient "Connection: Close\r\n";
    print $sockClient "Content-Type: text/html\r\n";
    print $sockClient "Content-Length: " . length($strHTML) . "\r\n\r\n";
    print $sockClient $strHTML;
  }

  if ($strMethod ne '')
  {
    my $addrClient = $sockClient->peerhost() . ':' . $sockClient->peerport();  #client ip address:port
    my $addrServer = $sockClient->sockhost() . ':80';  #server ip address:port
    my $strLdate = sprintf("%s %02d %02d:%02d:%02d", $txtMonths[$valMon], $valMday, $valHour, $valMin, $valSec);  #log date
    open(OUTLOG, ">>", '/var/log/http.log');  #open http log
    print OUTLOG "$strLdate $addrClient->$addrServer \"$strMethod $strURL\" \"$strHost\" \"$strReferer\" \"$strAgent\"\n";  #write http request to log
    close(OUTLOG);  #close log file
  }

  shutdown($sockClient, SHUT_RDWR);  #shutdown client socket
  close($sockClient);  #close client socket
}

umask(0);  #allow permissions

while (my $sockAccept = $sockListen->accept)
{
  #start process with client socket
  async(\&processReq, $sockAccept)->detach;
}

sleep(10);  #wait for threads to finish
