#!/usr/bin/perl

#  laconic.pl - Version 1.0.4  04 Jan 21
#  Laconic - Simple HTTP Server
#  Copyright 2020-2021 Del Castle
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

use strict;
use warnings;
use threads;
use Fcntl;
use File::Find;
use File::Path qw(make_path);
use IO::Compress::Gzip qw(gzip $GzipError);
use IO::Select;
use IO::Socket::INET;

my $optDump = 1;  #write requests to file
my $strKnock = 'secret';  #code word to open firewall for splunk
my @txtDays = qw(Sun Mon Tue Wed Thu Fri Sat Sun);
my @txtMonths = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);
my %valMonths = qw(january 1 february 2 march 3 april 4 may 5 june 6 july 7 august 8 september 9 october 10 november 11 december 12);

#listening socket to receive request
my $sockListen = IO::Socket::INET->new(Listen => 10,
                                       LocalPort => 8123,
                                       Proto => 'tcp',
                                       ReuseAddr => 1) or die "laconic error: new listen socket failed\n";

#capture kill to exit safely
$SIG{INT} = sub { close($sockListen); };
$SIG{TERM} = sub { close($sockListen); };

my $cntWeb = time();  #number to identify request
my $icoFav = pack('H*', '000001000100101000000100200068040000160000002800000010000000200000000100200000000000000000000000000000000000000000000000000000000000000080ff000080ff0000ffff000080ff008080ff00ffffff00ffffff00ffffff00ffffff008080ff008000ff00ff00ff008000ff008000ff0000000000000000000080ff000080ff0000ffff000080ff008080ff00ffffff00ffffff00ffffff00ffffff008080ff008000ff00ff00ff008000ff008000ff00000000000000400000bfff000080ff0000ffff004080ff008080ff00ffffff00ffffff00ffffff00ffffff008080ff008040ff00ff00ff008000ff00bf00ff00000040000000800000ffff000080ff0000ffff008080ff008080ff00ffffff00ffffff00ffffff00ffffff008080ff008080ff00ff00ff008000ff00ff00ff00000080000055bf0000ffff000080ff0000bfff00bfbfff008080ff00ffffff00ffffff00ffffff00ffffff008080ff00bfbfff00bf00ff008000ff00ff00ff005500bf000080ff0000ffff000080ff000080ff00ffffff008080ff00ffffff00ffffff00ffffff00ffffff008080ff00ffffff008000ff008000ff00ff00ff008000ff000080ff0000ffff0000ffff000080ff00ffffff00ffffff00ffffff00ffffff00ffffff00ffffff00ffffff00ffffff008000ff00ff00ff00ff00ff008000ff000000800000ffff0000ffff0000ffff008080ff00ffffff00ffffff00ffffff00ffffff00ffffff00ffffff008080ff00ff00ff00ff00ff00ff00ff000000800000000000000080000055bf0000ffff0000bfff000080ff00bfbfff00ffffff00ffffff00bfbfff008000ff00bf00ff00ff00ff005500bf0000008000000000000000000000000000000000000080ff0000ffff000080ff0000008000ffffff00ffffff00000080008000ff00ff00ff008000ff0000000000000000000000000000000000000000000055bf0000ffff0000ffff0000bfff00bfbfff00ffffff00ffffff00bfbfff00bf00ff00ff00ff00ff00ff005500bf000000000000000000000000000000400000bfff0000ffff0000ffff004080ff00ffffff00ffffff00ffffff00ffffff008040ff00ff00ff00ff00ff00bf00ff000000400000000000000000000000800000ffff0000ffff0000ffff008080ff00ffffff00ffffff00ffffff00ffffff008080ff00ff00ff00ff00ff00ff00ff000000800000000000000000000000400000bfff0000ffff0000ffff004080ff00ffffff00ffffff00ffffff00ffffff008040ff00ff00ff00ff00ff00bf00ff00000040000000000000000000000000000055bf0000ffff0000ffff0000bfff00bfbfff00ffffff00ffffff00bfbfff00bf00ff00ff00ff00ff00ff005500bf0000000000000000000000000000000000000000000055bf000080ff000055bf00000040008080ff008080ff00000040005500bf008000ff005500bf0000000000000000000000008001000080010000800100008001000080010000000000000000000080010000e0070000e2470000e0070000c0030000c0030000c0030000e0070000f66f0000');
my %filesRaw;  #store site files
my %filesGzip;  #store gzipped copy of site files
my %filesMod;  #modified date for site files

#create new file
sub createFile
{
  if (! -e $_[0])
  {
    my $outFile;
    open($outFile, '>', $_[0]) or die "laconic error: open new file failed - $!\n";  #open new file
    print $outFile $_[1];  #write contents to file
    close($outFile);
  }
}

createFile('/var/www/favicon.ico', $icoFav);
createFile('/var/www/index.html', '<html><head><title>Under Construction</title></head><body><p>Website Currently Unavailable - Under Construction</p></body></html>');
createFile('/var/www/404.html', '<html><head><title>Page Not Found</title></head><body><h2>404 - Page Not Found</h2></body></html>');
createFile('/var/www/pi.html', '<html><head><title>Laconic</title></head><body><h3>&pi;</h3></body></html>');

#find and store site files
sub wanted
{
  if (-e -f $File::Find::name)
  {
    my $fileName = $File::Find::name;
    $fileName =~ s/\/var\/www//;  #remove path
    my $inFile;
    open($inFile, '<:raw', $File::Find::name) or die "laconic error: open find file failed - $!\n";
    read($inFile, $filesRaw{$fileName}, -s $inFile);  #read full file
    close($inFile);
    gzip \$filesRaw{$fileName} => \$filesGzip{$fileName} or die "laconic error: gzip file failed - $GzipError\n";  #file gzip copy
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
  print $sockOut $strOut if ($sockOut->connected());  #print to socket
  print $fileOut $strOut if ($optDump);  #print to file
}

#process request
sub processWeb
{
  my $sockClient = shift;  #client socket
  my $idWeb = shift;  #request identifier
  my $flagClient = fcntl($sockClient, F_GETFL, 0) or die "laconic error: fcntl F_GETFL failed\n";
  fcntl($sockClient, F_SETFL, $flagClient | O_NONBLOCK) or die "laconic error: fcntl F_SETFL failed\n";  #make client socket non-blocking
  my $strConn = '';  #connection ip addresses:ports
  $strConn = $sockClient->peerhost() . ':' . $sockClient->peerport() . '->' . $sockClient->sockhost() . ':80' if ($sockClient->connected());
  my $sockSelect = IO::Select->new($sockClient);
  my @sockReady;

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
          my $dataHTML;
          my $inFile;
          open($inFile, '<', $fileName) or die "laconic error: open request file failed - $!\n";
          read($inFile, $dataHTML, -s $inFile);  #read full file
          close($inFile);
          $dataHTML =~ s/&/&amp;/sg;  #encode reserved &
          $dataHTML =~ s/</&lt;/sg;  #encode reserved <
          $dataHTML =~ s/>/&gt;/sg;  #encode reserved >
          $dataHTML = "<html><head><title>" . ucfirst($idType) . " - $idFile</title></head><body><pre>$dataHTML</pre></body></html>";

          my $dataSize = length($dataHTML);
          print $sockClient "HTTP/1.1 200 OK\r\n",
                            "Date: " . timeHTTP(time()) . "\r\n",
                            "Server: Laconic\r\n",
                            "Last-Modified: " . timeHTTP((stat($fileName))[9]) . "\r\n",
                            "Connection: close\r\n",
                            "Content-Type: text/html\r\n",
                            "Accept-Ranges: none\r\n",
                            "Content-Length: $dataSize\r\n\r\n" if ($sockClient->connected());
          my $dataOffset = 0;  #data chunk offset
          while ($dataOffset < $dataSize)
          {
            if (@sockReady = $sockSelect->can_write(3))  #send buffer clear
            {
              if ($sockClient->connected())
              {
                print $sockClient substr($dataHTML, $dataOffset, 8192);  #send file in chunks
                $dataOffset += 8192;
              }
              else
              {
                last;
              }
            }
          }
        }
      }
      elsif ($strLine =~ /^(GET|HEAD|POST|PUT|DELETE|CONNECT|OPTIONS|TRACE|PATCH)\s([^\s]+)\sHTTP/)
      {
        my ($strMethod, $strURL, $strHost, $strReferer, $strAgent, $strStatus, $fileHTML) = ($1, $2, '-', '-', '-', '404 Not Found', '/404.html');  #client request fields, default values
        $strURL =~ s/(")/sprintf('%%%02X', ord($1))/seg;  #encode quotes
        if ($strMethod =~ /^(GET|HEAD)$/)
        {
          if ($strURL eq '/')  #set default site to index.html
          {
            $strStatus = '200 OK';
            $fileHTML = '/index.html';
          }
          elsif ($strURL eq "/$strKnock")  #firewall open request
          {
            my $iptClient = 'INPUT -i enp1s0 -p tcp -s ' . $sockClient->peerhost() . ' --dport 8000 -m state --state NEW -j ACCEPT';  #iptables allow client to splunk web
            system("sudo iptables -C $iptClient || sudo iptables -A $iptClient");  #check if rule exists first
            $strStatus = '201 Created';
            $fileHTML = '/pi.html';
          }
          elsif ($strURL =~/^[\/\w\-.]{4,100}$/)
          {
            if (exists $filesRaw{$strURL})
            {
              $strStatus = '200 OK';
              $fileHTML = $strURL;
            }
          }
        }

        my ($valSec, $valMin, $valHour, $valMday, $valMon, $valYear, $valWday, $valYday, $valIsdst) = gmtime();  #current utc time
        my $filePath = sprintf('/var/log/web/20%02d/%02d/%02d', $valYear - 100, $valMon + 1, $valMday);  #save file path
        make_path($filePath, { mode => 0750 }) if ($optDump);  #create save file path if it doesn't exist
        my $fileWeb = "$filePath/web-$idWeb.txt";
        my $outWeb;
        if ($optDump)
        {
          open($outWeb, '>', $fileWeb) or die "laconic error: open dump file failed - $!\n";  #write request to file
          print $outWeb "$strConn\r\n\r\n";
          print $outWeb $strLine;  #write line to file
        }

        my $filePtr = \$filesRaw{$fileHTML};  #send raw file
        my $recvSize = length($strLine);  #received data size
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
          elsif ($strLine =~ /^Accept-Encoding: .*(\*|gzip).*\r\n$/)
          {
            $filePtr = \$filesGzip{$fileHTML};  #send gzipped file
          }
        }

        my $fileSize = length($$filePtr);
        print $outWeb "\r\n\r\n" if ($optDump);
        printOut($sockClient, $outWeb, "HTTP/1.1 $strStatus\r\n");
        printOut($sockClient, $outWeb, "Date: " . timeHTTP(time()) . "\r\n");
        printOut($sockClient, $outWeb, "Server: Laconic\r\n");
        printOut($sockClient, $outWeb, "Last-Modified: " . timeHTTP($filesMod{$fileHTML}) . "\r\n");
        printOut($sockClient, $outWeb, "Connection: close\r\n");
        printOut($sockClient, $outWeb, "Content-Encoding: gzip\r\n") if ($filePtr == \$filesGzip{$fileHTML});
        printOut($sockClient, $outWeb, "Content-Type: " . mimeHTTP($fileHTML) . "\r\n");
        printOut($sockClient, $outWeb, "Accept-Ranges: none\r\n");
        printOut($sockClient, $outWeb, "Content-Length: $fileSize\r\n\r\n");
        if ($strMethod eq 'GET')
        {
          my $fileOffset = 0;  #file chunk offset
          while ($fileOffset < $fileSize)
          {
            if (@sockReady = $sockSelect->can_write(3))  #send buffer clear
            { 
              if ($sockClient->connected())
              {
                print $sockClient substr($$filePtr, $fileOffset, 8192);  #send file in chunks
                $fileOffset += 8192;
              }
              else
              {
                last;
              }
            }
          }
        }

        close($outWeb) if ($optDump);  #close request file

        my $outLog;
        open($outLog, '>>', '/var/log/http.log') or die "laconic error: open log file failed - $!\n";  #open http log
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
