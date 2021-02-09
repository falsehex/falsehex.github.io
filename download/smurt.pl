#!/usr/bin/perl

#  smurt.pl - Version 1.0.5  10 Feb 21
#  Smurt - SMTP Responder
#  Copyright 2020-2021 Del Castle
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

use strict;
use warnings;
use threads;
use Fcntl;
use File::Path qw(make_path);
use IO::Socket::INET;
use MIME::Base64 qw(encode_base64);

my $optDump = 1;  #write emails to file
my $strServer = 'smtp.server.com';  #server name
my @txtDays = qw(Sun Mon Tue Wed Thu Fri Sat Sun);
my @txtMonths = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);

#listening socket to receive email
my $sockListen = IO::Socket::INET->new(Listen => 10,
                                       LocalPort => 5123,
                                       Proto => 'tcp',
                                       ReuseAddr => 1) or die "smurt error: new listen socket failed\n";

#capture kill to exit safely
$SIG{INT} = sub { close($sockListen); };
$SIG{TERM} = sub { close($sockListen); };

my $cntMail = time();  #number to identify email

#print to socket and file
sub printOut
{
  my ($sockOut, $fileOut, $strOut) = @_;
  print $sockOut $strOut if ($sockOut->connected());  #print to socket
  $$fileOut .= "S: $strOut" if ($optDump);  #print to file
} 

#process email
sub processMail
{
  my $sockClient = shift;  #client socket
  my $idMail = shift;  #email identifier
  my $flagClient = fcntl($sockClient, F_GETFL, 0) or die "smurt error: fcntl F_GETFL failed\n";
  fcntl($sockClient, F_SETFL, $flagClient | O_NONBLOCK) or die "smurt error: fcntl F_SETFL failed\n";  #make client socket non-blocking
  my $strConn = '';  #connection ip addresses:ports
  $strConn = $sockClient->peerhost() . ':' . $sockClient->peerport() . '->' . $sockClient->sockhost() . ':25' if ($sockClient->connected());

  my $timeOut = 30;  #socket timeout
  my $optAuth = 0;  #smtp auth tracking
  my $recvSize = 0;  #received data size
  my $strLine;  #read line
  my ($strMTA, $strFrom, $strSubject) = ('', '-', '-');  #client email fields

  my $strMail = "$strConn\r\n\r\n";  #email transaction
  printOut ($sockClient, \$strMail, "220 $strServer SMTP Ready\r\n");

  while ($timeOut)
  {
    while ($strLine = <$sockClient>)  #read line from client socket
    {
      $recvSize += length($strLine);
      if ($optDump)
      {
        $strMail .= "C: $strLine";  #write line to file
        $strMail .= "\r\n" if ($strLine !~ /\n$/);
      }
 
      #reply to smtp commands
      if ($strLine =~ /^HELO\s\[?([\w\-\.]+)\]?/i)
      {
        $strMTA = $1;
        printOut($sockClient, \$strMail, "250 Hello $strMTA\r\n");
      }
      elsif ($strLine =~ /^EHLO\s\[?([\w\-\.]+)\]?/i)
      {
        $strMTA = $1;
        printOut($sockClient, \$strMail, "250-$strServer Hello $strMTA\r\n");
        printOut($sockClient, \$strMail, "250-SIZE 5242880\r\n");
        printOut($sockClient, \$strMail, "250 DSN\r\n");
      }
      elsif ($strLine =~ /^STARTTLS\r\n/i)
      {
        printOut($sockClient, \$strMail, "454 TLS currently unavailable\r\n");
      }
      elsif ($strLine =~ /^AUTH\sPLAIN\r\n/i)
      {
        $optAuth = 2;
        printOut($sockClient, \$strMail, "334\r\n");
      }
      elsif ($strLine =~ /^AUTH\sLOGIN\r\n/i)
      {
        $optAuth = 1;
        printOut($sockClient, \$strMail, "334 VXNlcm5hbWU6\r\n");  #Username:
      }
      elsif ($strLine =~ /^AUTH\sCRAM-MD5\r\n/i)
      {
        $optAuth = 2;
        printOut($sockClient, \$strMail, "334 " . encode_base64('KEY' . time()) . "\r\n");
      }
      elsif ($strLine =~ /^MAIL\sFROM:<(.+?)>/i)
      {
        $strFrom = $1;
        $strFrom =~ s/(")/sprintf('%%%02X', ord($1))/seg;  #encode quotes
        printOut($sockClient, \$strMail, "250 OK\r\n");
      }
      elsif ($strLine =~ /^(RCPT\sTO:|\.\r\n|RSET\r\n|SEND\sFROM:|SOML\sFROM:|SAML\sFROM:|VRFY\s|EXPN\s|NOOP|TURN\r\n)/i)
      {
        printOut($sockClient, \$strMail, "250 OK\r\n");
      }
      elsif ($strLine =~ /^DATA\r\n/i)
      {
        printOut($sockClient, \$strMail, "354 End data with <CR><LF>.<CR><LF>\r\n");
      }
      elsif ($strLine =~ /^HELP/i)
      {
        printOut($sockClient, \$strMail, "214 See RFC 5321\r\n");
      }
      elsif ($strLine =~ /^QUIT\r\n/i)
      {
        $timeOut = 0;
        printOut($sockClient, \$strMail, "221 Bye\r\n");
        last;
      }
      elsif ($strLine =~ /^Subject:\s?(.+)\r\n$/i)
      {
        $strSubject = $1 if ($strSubject eq '-');
        $strSubject =~ s/(")/sprintf('%%%02X', ord($1))/seg;  #encode quotes
      }
      elsif ($optAuth == 1)
      {
        $optAuth = 2;
        printOut($sockClient, \$strMail, "334 UGFzc3dvcmQ6\r\n");  #Password:
      }
      elsif ($optAuth == 2)
      {
        $optAuth = 0;
        printOut($sockClient, \$strMail, "235 2.7.0 Authentication successful\r\n");
      }
    }
    if ($timeOut)
    {
      sleep(1);
      $timeOut--;
    }
  }

  if ($strMTA ne '')
  {
    my ($valSec, $valMin, $valHour, $valMday, $valMon, $valYear, $valWday, $valYday, $valIsdst) = gmtime();  #current utc time
    if ($optDump)
    {
      my $filePath = sprintf('/var/log/mail/20%02d/%02d/%02d', $valYear - 100, $valMon + 1, $valMday);  #save file path
      make_path($filePath, { mode => 0750 });  #create save file path if it doesn't exist
      my $fileMail = "$filePath/mail-$idMail.txt";
      my $outMail;
      if (open($outMail, '>', $fileMail))  #write email to file
      {
        print $outMail $strMail;
        close($outMail);  #close email file
      }
    }

    my $outLog;
    if (open($outLog, '>>', '/var/log/smtp.log'))  #open mail log
    {
      print $outLog sprintf('%s %02d %02d:%02d:%02d', $txtMonths[$valMon], $valMday, $valHour, $valMin, $valSec) . " $strConn $idMail \"$strMTA\" \"$strFrom\" \"$strSubject\" $recvSize\n";  #log mail fields
      close($outLog);  #close log file
    }
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

sleep(5);  #wait for threads to finish
