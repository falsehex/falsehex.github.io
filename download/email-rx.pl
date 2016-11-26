#!/usr/bin/perl

#  email-rx.pl - Version 0.4  07 Sep 16
#  eMail-RX - MTA-To-File
#  Copyright 2014-2016 Del Castle

#  eMail-RX receives email from a MTA and writes it to file.

#  Usage: perl email-rx.pl

use strict;
use warnings;
use threads;
use File::Path qw(make_path);
use IO::Socket::INET;

my @txtMonths = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);
my @txtDays = qw(Sun Mon Tue Wed Thu Fri Sat Sun);

my $cntMail = time();  #number to identify email

#listening socket to receive email
my $sockListen = IO::Socket::INET->new(LocalPort => 25,
                                       Proto => 'tcp',
                                       Listen => 100,
                                       ReuseAddr => 1) or die "listen socket error\n";

#capture kill to exit safely
$SIG{INT} = sub { close($sockListen); };
$SIG{TERM} = sub { close($sockListen); };

#process email
sub processMail
{
  my $sockClient = shift;  #client socket
  my $idMail = shift;  #email identifier

  my $strLine;  #read line
  my ($valSec, $valMin, $valHour, $valMday, $valMon, $valYear, $valWday, $valYday, $valIsdst) = gmtime();  #current UTC time

  my $filePath = sprintf("/var/spool/mail/20%02d/%02d/%02d", $valYear - 100, $valMon + 1, $valMday);  #save file path
  make_path($filePath, { mode => 0755 });  #create save file path if it doesn't exist
  my $fileMail = "$filePath/mail-$idMail.txt";
  open(MAIL, ">", $fileMail);  #write email received to file

  print $sockClient "220 email-rx.com\r\n";

  while ($strLine = <$sockClient>)  #read line from client socket
  {
    print MAIL $strLine;  #write line to file

    #reply to SMTP commands
    if ($strLine =~ /^HELO/)
    {
      print $sockClient "250 email-rx.com\r\n";
    }
    elsif ($strLine =~ /^EHLO/)
    {
      print $sockClient "250-email-rx.com\r\n250-SIZE 20480000\r\n250 DSN\r\n";
    }
    elsif ($strLine =~ /^(MAIL FROM:|RCPT TO:|\.\r\n|RSET\r\n|SEND FROM:|SOML FROM:|SAML FROM:|VRFY |EXPN |NOOP\r\n|TURN\r\n)/)
    {
      print $sockClient "250 OK\r\n";
    }
    elsif ($strLine =~ /^DATA\r\n/)
    {
      print $sockClient "354 End data with <CR><LF>.<CR><LF>\r\n";
    }
    elsif ($strLine =~ /^HELP\r\n/)
    {
      print $sockClient "214 Server\r\n";
    }
    elsif ($strLine =~ /^QUIT\r\n/)
    {
      print $sockClient "221 Bye\r\n";
      last;
    }
  }

  close(MAIL);  #close email received file
  close($sockClient);  #close client socket
}

umask(0);  #allow permissions

while (my $sockAccept = $sockListen->accept)
{
  #start process with client socket and number to identify email
  async(\&processMail, $sockAccept, ++$cntMail)->detach;
}

sleep(10);  #wait for threads to finish
