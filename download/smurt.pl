#!/usr/bin/perl

#  smurt.pl - Version 1.0.1  14 Nov 20
#  Smurt - SMTP Responder
#  Copyright 2020 Del Castle
#
#  Installation:
#    cp smurt.pl /usr/local/bin/
#    useradd -r -s /usr/sbin/nologin www
#    touch /var/log/smtp.log
#    mkdir /var/log/mail
#    chown www:www /usr/local/bin/smurt.pl /var/log/smtp.log /var/log/mail
#    chmod 750 /usr/local/bin/smurt.pl
#    chmod 644 /var/log/smtp.log
#    chmod 750 /var/log/mail
#    Add to /etc/crontab: * *  * * *  www  ps -ef | grep smurt.pl | grep -v grep >/dev/null || smurt.pl >/dev/null 2>&1 &
#    Port forward 25 to 5123 on firewall

use autodie;
use strict;
use warnings;
use threads;
use Fcntl;
use File::Path qw(make_path);
use IO::Socket::INET;

my $strServer = 'smtp.server.com';  #server name
my @txtDays = qw(Sun Mon Tue Wed Thu Fri Sat Sun);
my @txtMonths = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);

#listening socket to receive email
my $sockListen = IO::Socket::INET->new(LocalPort => 5123,
                                       Proto => 'tcp',
                                       Listen => 100,
                                       ReuseAddr => 1) or die "listen socket error\n";

#capture kill to exit safely
$SIG{INT} = sub { close($sockListen); };
$SIG{TERM} = sub { close($sockListen); };

my $cntMail = time();  #number to identify email

#process email
sub processMail
{
  my $sockClient = shift;  #client socket
  my $idMail = shift;  #email identifier
  my $flagClient = fcntl($sockClient, F_GETFL, 0);
  fcntl($sockClient, F_SETFL, $flagClient | O_NONBLOCK);  #make client socket non-blocking
  my $addrClient = $sockClient->peerhost() . ':' . $sockClient->peerport();  #client ip address:port
  my $addrServer = $sockClient->sockhost() . ':25';  #server ip address:port

  my $timeOut = 30;  #socket timeout
  my $strLine;  #read line
  my ($strMTA, $strFrom, $strSubject) = ('', '-', '-');  #client email fields
  my ($valSec, $valMin, $valHour, $valMday, $valMon, $valYear, $valWday, $valYday, $valIsdst) = gmtime();  #current UTC time

  my $filePath = sprintf('/var/log/mail/20%02d/%02d/%02d', $valYear - 100, $valMon + 1, $valMday);  #save file path
  make_path($filePath, { mode => 0750 });  #create save file path if it doesn't exist
  my $fileMail = "$filePath/mail-$idMail.txt";
  my $outMail;
  open($outMail, '>', $fileMail);  #write email received to file
  print $outMail "$addrClient->$addrServer\r\n";

  print $sockClient "220 $strServer SMTP Ready\r\n";

  while ($timeOut)
  {
    while ($strLine = <$sockClient>)  #read line from client socket
    {
      print $outMail $strLine;  #write line to file
      print $outMail "\r\n" if ($strLine !~ /\n$/);
 
      #reply to SMTP commands
      if ($strLine =~ /^HELO\s([\w\-\.]+)/i)
      {
        $strMTA = $1;
        print $sockClient "250 Hello $strMTA\r\n";
      }
      elsif ($strLine =~ /^EHLO\s([\w\-\.]+)/i)
      {
        $strMTA = $1;
        print $sockClient "250-$strServer Hello $strMTA\r\n250-SIZE 20480000\r\n250 DSN\r\n";
      }
      elsif ($strLine =~ /^STARTTLS\r\n/i)
      {
        print $sockClient "454 TLS currently unavailable\r\n";
      }
      elsif ($strLine =~ /^AUTH\s/i)
      {
        print $sockClient "235 2.7.0 Authentication successful\r\n";
      }
      elsif ($strLine =~ /^MAIL\sFROM:<(.+?)>/i)
      {
        $strFrom = $1;
        $strFrom =~ s/(")/sprintf("%%%02X", ord($1))/seg;  #encode quotes
        print $sockClient "250 OK\r\n";
      }
      elsif ($strLine =~ /^(RCPT\sTO:|\.\r\n|RSET\r\n|SEND\sFROM:|SOML\sFROM:|SAML\sFROM:|VRFY\s|EXPN\s|NOOP|TURN\r\n)/i)
      {
        print $sockClient "250 OK\r\n";
      }
      elsif ($strLine =~ /^DATA\r\n/i)
      {
        print $sockClient "354 End data with <CR><LF>.<CR><LF>\r\n";
      }
      elsif ($strLine =~ /^HELP/i)
      {
        print $sockClient "214 Server\r\n";
      }
      elsif ($strLine =~ /^QUIT\r\n/i)
      {
        print $sockClient "221 Bye\r\n";
        $timeOut = 0;
        last;
      }
      elsif ($strLine =~ /^Subject:\s?(.+)\r\n$/i)
      {
        $strSubject = $1 if ($strSubject eq '-');
        $strSubject =~ s/(")/sprintf("%%%02X", ord($1))/seg;  #encode quotes
      }
    }
    if ($timeOut)
    {
      sleep(1);
      $timeOut--;
    }
  }

  close($outMail);  #close email received file

  if ($strMTA ne '')
  {
    my $outLog;
    open($outLog, '>>', '/var/log/smtp.log');  #open mail log
    print $outLog sprintf('%s %02d %02d:%02d:%02d', $txtMonths[$valMon], $valMday, $valHour, $valMin, $valSec) . " $addrClient->$addrServer $idMail \"$strMTA\" \"$strFrom\" \"$strSubject\" " . (-s $fileMail) . "\n";  #log mail fields
    close($outLog);  #close log file
  }

  shutdown($sockClient, SHUT_RDWR);  #shutdown client socket
  close($sockClient);  #close client socket
}

umask(0);  #allow permissions

while (my $sockAccept = $sockListen->accept)
{
  #start process with client socket and number to identify email
  async(\&processMail, $sockAccept, ++$cntMail)->detach;
}

sleep(10);  #wait for threads to finish
