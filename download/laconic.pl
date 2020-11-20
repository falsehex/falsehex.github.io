#!/usr/bin/perl

#  laconic.pl - Version 1.0.2  21 Nov 20
#  Laconic - Simple HTTP Server
#  Copyright 2020 Del Castle
#
#  Installation:
#    cp laconic.pl /usr/local/bin/
#    useradd -r -s /usr/sbin/nologin www
#    touch /var/log/http.log
#    mkdir /var/log/web
#    mkdir /var/www
#    chown www:www /usr/local/bin/laconic.pl /var/log/http.log /var/log/web /var/www
#    chmod 750 /usr/local/bin/laconic.pl
#    chmod 644 /var/log/http.log
#    chmod 750 /var/log/web
#    chmod 750 /var/www
#    Add to /etc/crontab: * *  * * *  www  ps -ef | grep laconic.pl | grep -v grep >/dev/null || laconic.pl >/dev/null 2>&1 &
#    Port forward 80 to 8123 on firewall

use autodie;
use strict;
use warnings;
use threads;
use Fcntl;
use File::Find;
use File::Path qw(make_path);
use IO::Socket::INET;

my $optDump = 1;  #write requests to file
my $strKnock = 'secret';  #code word to open firewall for splunk
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

my $cntWeb = time();  #number to identify request
my $icoFav = pack('H*', '000001000100101000000100200068040000160000002800000010000000200000000100200000000000000000000000000000000000000000000000000000000000000080ff000080ff0000ffff000080ff008080ff00ffffff00ffffff00ffffff00ffffff008080ff008000ff00ff00ff008000ff008000ff0000000000000000000080ff000080ff0000ffff000080ff008080ff00ffffff00ffffff00ffffff00ffffff008080ff008000ff00ff00ff008000ff008000ff00000000000000400000bfff000080ff0000ffff004080ff008080ff00ffffff00ffffff00ffffff00ffffff008080ff008040ff00ff00ff008000ff00bf00ff00000040000000800000ffff000080ff0000ffff008080ff008080ff00ffffff00ffffff00ffffff00ffffff008080ff008080ff00ff00ff008000ff00ff00ff00000080000055bf0000ffff000080ff0000bfff00bfbfff008080ff00ffffff00ffffff00ffffff00ffffff008080ff00bfbfff00bf00ff008000ff00ff00ff005500bf000080ff0000ffff000080ff000080ff00ffffff008080ff00ffffff00ffffff00ffffff00ffffff008080ff00ffffff008000ff008000ff00ff00ff008000ff000080ff0000ffff0000ffff000080ff00ffffff00ffffff00ffffff00ffffff00ffffff00ffffff00ffffff00ffffff008000ff00ff00ff00ff00ff008000ff000000800000ffff0000ffff0000ffff008080ff00ffffff00ffffff00ffffff00ffffff00ffffff00ffffff008080ff00ff00ff00ff00ff00ff00ff000000800000000000000080000055bf0000ffff0000bfff000080ff00bfbfff00ffffff00ffffff00bfbfff008000ff00bf00ff00ff00ff005500bf0000008000000000000000000000000000000000000080ff0000ffff000080ff0000008000ffffff00ffffff00000080008000ff00ff00ff008000ff0000000000000000000000000000000000000000000055bf0000ffff0000ffff0000bfff00bfbfff00ffffff00ffffff00bfbfff00bf00ff00ff00ff00ff00ff005500bf000000000000000000000000000000400000bfff0000ffff0000ffff004080ff00ffffff00ffffff00ffffff00ffffff008040ff00ff00ff00ff00ff00bf00ff000000400000000000000000000000800000ffff0000ffff0000ffff008080ff00ffffff00ffffff00ffffff00ffffff008080ff00ff00ff00ff00ff00ff00ff000000800000000000000000000000400000bfff0000ffff0000ffff004080ff00ffffff00ffffff00ffffff00ffffff008040ff00ff00ff00ff00ff00bf00ff00000040000000000000000000000000000055bf0000ffff0000ffff0000bfff00bfbfff00ffffff00ffffff00bfbfff00bf00ff00ff00ff00ff00ff005500bf0000000000000000000000000000000000000000000055bf000080ff000055bf00000040008080ff008080ff00000040005500bf008000ff005500bf0000000000000000000000008001000080010000800100008001000080010000000000000000000080010000e0070000e2470000e0070000c0030000c0030000c0030000e0070000f66f0000');
my %filesRaw;
my %filesMod;

#create text file
sub createFile
{
  if (! -e $_[0])
  {
    my $outFile;
    open($outFile, '>', $_[0]);  #open new file
    print $outFile $_[1];  #write contents to file
    close($outFile);
  }
}

createFile('/var/www/favicon.ico', $icoFav);
createFile('/var/www/index.html', '<html><head><title>Under Construction</title></head><body><p>Website Currently Unavailable - Under Construction</p></body></html>');
createFile('/var/www/404.html', '<html><head><title>Page Not Found</title></head><body><h2>404 - Page Not Found</h2></body></html>');
createFile('/var/www/pi.html', '<html><head><title>Laconic</title></head><body><h3>&pi;</h3></body></html>');

#file find
sub wanted
{
  if (-e -f $File::Find::name)
  {
    my $fileName = $File::Find::name;
    $fileName =~ s/\/var\/www//;  #remove path
    my $inFile;
    open($inFile, '<:raw', $File::Find::name);
    read($inFile, $filesRaw{$fileName}, -s $inFile);  #read full file
    close($inFile);
    $filesMod{$fileName} = (stat($File::Find::name))[9];  #file modified date
  }
}

finddepth(\&wanted, '/var/www');

#server date
sub timeHTTP
{
  my ($valSec, $valMin, $valHour, $valMday, $valMon, $valYear, $valWday, $valYday, $valIsdst) = gmtime($_[0]);
  return sprintf('%s, %02d %s 20%02d %02d:%02d:%02d GMT', $txtDays[$valWday], $valMday, $txtMonths[$valMon], $valYear - 100, $valHour, $valMin, $valSec);
}

#determine mime type
sub mimeHTTP
{
  my ($fileExt) = $_[0] =~ /(\.[^.]+)$/;  #file extension
  if ($fileExt =~ /\.html$/i) { return 'text/html'; }
  elsif ($fileExt =~ /\.css$/i) { return 'text/css'; }
  elsif ($fileExt =~ /\.ico$/i) { return 'image/x-icon'; }
  elsif ($fileExt =~ /\.jpg$/i) { return 'image/jpeg'; }
  elsif ($fileExt =~ /\.png$/i) { return 'image/png'; }
  elsif ($fileExt =~ /\.gz$/i) { return 'application/gzip'; }
  else { return 'text/plain'; }
}

#print to socket and file
sub printOut
{
  my ($sockOut, $fileOut, $strOut) = @_;
  print $sockOut $strOut;  #print to socket
  print $fileOut $strOut if ($optDump);  #print to file
}

#process request
sub processWeb
{
  my $sockClient = shift;  #client socket
  my $idWeb = shift;  #request identifier
  my $flagClient = fcntl($sockClient, F_GETFL, 0);
  fcntl($sockClient, F_SETFL, $flagClient | O_NONBLOCK);  #make client socket non-blocking
  my $strConn = $sockClient->peerhost() . ':' . $sockClient->peerport() . '->' . $sockClient->sockhost() . ':80';  #connection ip addresses:ports

  my $timeOut = 3;  #socket timeout
  my $strLine;  #read line

  while ($timeOut)
  {
    if (defined($strLine = <$sockClient>))  #read line from client socket
    {
      $timeOut = 0;

      if ($strLine =~ /^GET\s\/\?year=(\d{4})&month=([a-z]+)&day=(\d{1,2})&(web|mail)=(\d+)\sHTTP/)  #retrieve file request
      {
        my ($dateYear, $dateMonth, $dateDay, $idType, $idFile) = ($1, $2, $3, $4, $5);
        my $fileName = sprintf('/var/log/%s/%d/%02d/%02d/%s-%d.txt', $idType, $dateYear, $valMonths{$dateMonth}, $dateDay, $idType, $idFile);
        if (-e -s $fileName)
        {
          my $strHTML;
          my $inFile;
          open($inFile, '<', $fileName);
          read($inFile, $strHTML, -s $inFile);  #read full file
          close($inFile);
          $strHTML =~ s/&/&amp;/sg;  #encode reserved &
          $strHTML =~ s/</&lt;/sg;  #encode reserved <
          $strHTML =~ s/>/&gt;/sg;  #encode reserved >
          $strHTML = "<html><head><title>" . ucfirst($idType) . " - $idFile</title></head><body><pre>$strHTML</pre></body></html>";

          print $sockClient "HTTP/1.1 200 OK\r\n";
          print $sockClient "Date: " . timeHTTP(time()) . "\r\n";
          print $sockClient "Server: Laconic\r\n";
          print $sockClient "Last-Modified: " . timeHTTP((stat($fileName))[9]) . "\r\n";
          print $sockClient "Connection: close\r\n";
          print $sockClient "Content-Type: text/html\r\n";
          print $sockClient "Content-Length: " . length($strHTML) . "\r\n\r\n";
          print $sockClient $strHTML;
        }
      }
      elsif ($strLine =~ /^(GET|HEAD|POST|PUT|DELETE|CONNECT|OPTIONS|TRACE|PATCH)\s([^\s]+)\sHTTP/)
      {
        my ($strMethod, $strURL, $strHost, $strReferer, $strAgent, $strStatus, $fileHTML) = ($1, $2, '-', '-', '-', '404 Not Found', '/404.html');  #client request fields, default values
        $strURL =~ s/(")/sprintf('%%%02X', ord($1))/seg;  #encode quotes
        my $recvSize = length($strLine);  #received data size
        my ($valSec, $valMin, $valHour, $valMday, $valMon, $valYear, $valWday, $valYday, $valIsdst) = gmtime();  #current utc time

        my $filePath = sprintf('/var/log/web/20%02d/%02d/%02d', $valYear - 100, $valMon + 1, $valMday);  #save file path
        make_path($filePath, { mode => 0750 }) if ($optDump);  #create save file path if it doesn't exist
        my $fileWeb = "$filePath/web-$idWeb.txt";
        my $outWeb;
        if ($optDump)
        {
          open($outWeb, '>', $fileWeb);  #write request to file
          print $outWeb "$strConn\r\n\r\n";
          print $outWeb $strLine;  #write line to file
        }

        while ($strLine = <$sockClient>)
        {
          $recvSize += length($strLine);
          if ($optDump)
          {
            print $outWeb $strLine;  #write line to file
            print $outWeb "\r\n" if ($strLine !~ /\n$/);
          }

          if ($strLine =~ /^Host:\s(.+)\r\n$/)
          {
            $strHost = $1;
            $strHost =~ s/(")/sprintf('%%%02X', ord($1))/seg;  #encode quotes
          }
          elsif ($strLine =~ /^Referer:\s(.+)\r\n$/)
          {
            $strReferer = $1;
            $strReferer =~ s/(")/sprintf('%%%02X', ord($1))/seg;  #encode quotes
          }
          elsif ($strLine =~ /^User-Agent:\s(.+)\r\n$/)
          {
            $strAgent = $1;
            $strAgent =~ s/(")/sprintf('%%%02X', ord($1))/seg;  #encode quotes
          }
        }

        if ($strMethod eq 'GET')
        {
          if ($strURL eq '/')  #set default site to index.html
          {
            $strStatus = '200 OK';
            $fileHTML = '/index.html';
          }
          elsif (exists $filesRaw{$strURL})
          {
            $strStatus = '200 OK';
            $fileHTML = $strURL;
          }
          elsif ($strURL eq "/$strKnock")  #firewall open request
          {
            my $iptClient = 'INPUT -i enp1s0 -p tcp -s ' . $sockClient->peerhost() . ' --dport 8000 -m state --state NEW -j ACCEPT';  #iptables allow client to splunk web
            system("sudo iptables -C $iptClient || sudo iptables -A $iptClient");  #check if rule exists first
            $strStatus = '201 Created';
            $fileHTML = '/pi.html';
          }
        }

        print $outWeb "\r\n\r\n" if ($optDump);
        printOut($sockClient, $outWeb, "HTTP/1.1 $strStatus\r\n");
        printOut($sockClient, $outWeb, "Date: " . timeHTTP(time()) . "\r\n");
        printOut($sockClient, $outWeb, "Server: Laconic\r\n");
        printOut($sockClient, $outWeb, "Last-Modified: " . timeHTTP($filesMod{$fileHTML}) . "\r\n");
        printOut($sockClient, $outWeb, "Connection: close\r\n");
        printOut($sockClient, $outWeb, "Content-Type: " . mimeHTTP($fileHTML) . "\r\n");
        printOut($sockClient, $outWeb, "Content-Length: " . length($filesRaw{$fileHTML}) . "\r\n\r\n");
        print $sockClient $filesRaw{$fileHTML};

        close($outWeb) if ($optDump);  #close request file

        my $outLog;
        open($outLog, '>>', '/var/log/http.log');  #open http log
        print $outLog sprintf('%s %02d %02d:%02d:%02d', $txtMonths[$valMon], $valMday, $valHour, $valMin, $valSec) . " $strConn $idWeb \"$strMethod $strURL\" \"$strHost\" \"$strReferer\" \"$strAgent\" " . substr($strStatus, 0, 3) . " $recvSize\n";  #log http request
        close($outLog);  #close log file
      }
    }
    if ($timeOut)
    {
      sleep(1);
      $timeOut--;
    }
  }

  shutdown($sockClient, SHUT_RDWR);  #shutdown client socket
  close($sockClient);  #close client socket
}

umask(0);  #allow permissions

while (my $sockAccept = $sockListen->accept)
{
  #start process with client socket and number to identify request
  async(\&processWeb, $sockAccept, ++$cntWeb)->detach;
}

sleep(5);  #wait for threads to finish
