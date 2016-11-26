Logalysis README - 27 May 16
============================

1. Setup
========

1.1 LAMP Server
===============
Logalysis needs to be installed on a LAMP (Linux, Apache, MySQL and PHP) server. The easiest setup is to install Ubuntu Server and select "LAMP server" and "OpenSSH server" when prompted to choose software to install.

1.2 Additional Packages
=======================
The following additional packages (and their dependencies) may be required:

  * tshark - pcap analysis.
  * make - compile patched Foremost and tcpflow.
  * g++ - compile patched Foremost and tcpflow.
  * libpcap-dev - compile patched tcpflow.
  * php5-mssql - if retrieving data from a Microsoft SQL Server database.

Additional packages can be installed using the command:

  sudo apt-get install <PACKAGE>

1.3 Configuration Files
=======================
Add the following line to "/etc/apache2/apache2.conf" to stop directory listings of files on the server via a web browser:

  IndexIgnore *

Add the following lines to "/etc/apache2/sites-available/default" to stop imported PHP files from being executed via a web browser (to analyse PHP files rename them, e.g. phpx):

  <Directory "/var/www/logalysis/files">
    <FilesMatch "\.(phtml|pht|php|php3)$">
      Order deny,allow
      Deny from all
    </FilesMatch>
  </Directory>

Change the "session.gc_maxlifetime" line in "/etc/php5/apache2/php.ini" to automatically logout the user in Logalysis after one day of inactivity:

  session.gc_maxlifetime = 86400

1.4 Logalysis Files
===================
audit_show.php - Displays a job's details change history.
blank.html - Blank page.
chart_layout.php - Frame layout for chart_search and chart_show sections.
chart_search.php - Displays criteria to create a chart from.
chart_show.php - Displays a chart.
common.php - Global settings and common PHP functions. See 1.5 Logalysis "common.php" File.
details_show.php - Displays a job's details.
file_edit.php - Displays/Saves a file, used to edit configuration files in the "SETTINGS" section.
file_import.php - Import a file from the OS running the browser.
file_layout.php - Frame layout for file_list, file_search and file_show sections.
file_list.php - Displays a list of files related to a job.
file_search.php - Displays criteria to create a file from.
file_show.php - Displays information about the file, a hex dump of the file, or the actual file content.
files/ - Contains files related to jobs under a directory named after the job's reference number (or SCRATCHPAD).
files/RT_Messages/ - Contains messages to be displayed in the "REAL-TIME" section. See 7.2 Real-time Messages.
fx/ - Contains files that help render HTML. Subdirectories: css - CSS, img - Images, js - JavaScript.
fx/css/etree.css - CSS for eTree (used for tree menus).
fx/css/logalysis.css - CSS for Logalysis.
fx/img/etree/ - Image files for eTree (used for tree menus).
fx/img/packet_posse.png - Logo image.
fx/img/packet_posse16.ico - Logo image as icon.
fx/js/chart_gfx.js - JavaScript for drawing HTML5 canvas graphs.
fx/js/edate.js - JavaScript for eDate (used for date/time input).
fx/js/esort.js - JavaScript for eSort (used for sorting tables by different columns).
fx/js/etree.js - JavaScript for eTree (used for tree menus).
fx/js/logalysis.js - Common JavaScript for Logalysis.
header.php - Top bar which displays UTC clock, new window, settings and logout items.
host_show.php - Displays/Saves host details for host lookup.
index.php - Login page. On successful login, frame layout for header, queue_list, job_list, menu_main and show sections.
job_list.php - Displays a list of jobs.
log_layout.php - Frame layout for log_list, log_search and log_show sections.
log_list.php - Displays a list of logs related to a job.
log_search.php - Displays criteria to create a log from.
log_show.php - Displays/Saves a log.
menu_main.php - Displays main menu.
note_layout.php - Frame layout for note_list and note_show sections.
note_list.php - Displays a list of notes related to a job.
note_show.php - Displays/Saves a note.
pcap_get.php - Download pcap file.
plugins/ - Contains all the various types of plug-ins.
plugins/chart/ - Contains chart search and generation plug-ins. See 3. Chart Plug-ins.
plugins/cred/ - Contains credentials for the various types of plug-ins. See 4. Credential Plug-ins.
plugins/disclaimer.php - Disclaimer text for login page.
plugins/edit/ - Contains configuration files that can be edited via the built-in editor (in the "SETTINGS" section).
plugins/file/ - Contains file search and generation plug-ins. See 5. File Plug-ins.
plugins/geoip/ - Contains files that enable IP-based geolocation.
plugins/log/ - Contains log search, generation and retrieval plug-ins. See 6. Log Plug-ins.
plugins/misc/ - Contains miscellaneous files.
plugins/note/ - Contains note and change templates. See 10. Note and Change Templates.
plugins/pcap/ - Contains pcap analysis scripts. See 9. pcap Plug-ins.
plugins/realtime/ - Contains real-time events plug-ins. See 7. Real-time Plug-ins.
plugins/report/ - Contains report search and generation plug-ins. See 8. Report Plug-ins.
plugins/status/ - Contains status plug-ins, which display the status of items.
queue_list.php - Displays a list of job status queues.
realtime_show.php - Displays a table of real-time events. Refreshes every 30 seconds.
report_search.php - Displays criteria to create a report from.
report_show.php - Displays a report.
settings_layout.html - Frame layout for settings_list and settings_show sections.
settings_list.php - Displays file editor, status, lists of all users and states if logged in user is a admin, otherwise shows the logged in user.
state_show.php - Displays a state's details.
user_show.php - Displays a user's details.
xtra/ - Contains files that are not installed in the /var/www/ directory. Delete this folder once contents has been installed.
xtra/bin/ - Copy these files to "/usr/local/bin/".
xtra/bin/add_job.pl - Create Logalysis job for inputted event. See 1.7 Logalysis "xtra/bin/add_job.pl" File.
xtra/bin/check_snort.sh - Shortcut for "snort_events.pl add | add_job.pl". See 1.8 Logalysis "xtra/bin/check_snort.sh" File.
xtra/bin/generate_pcap.sh - Generate pcap file using inputted criteria from pcap files dumped by "xtra/sbin/dump_pcap.sh".
xtra/bin/intrushield_events.pl - Check for new McAfee IntruShield events. See 1.7 Logalysis "xtra/bin/add_job.pl" File.
xtra/bin/snort_events.pl - Check for new Snort events. See 1.7 Logalysis "xtra/bin/add_job.pl" File.
xtra/bin/sourcefire_events.pl - Check for new Sourcefire IPS events. See 1.7 Logalysis "xtra/bin/add_job.pl" File.
xtra/bin/uncomp_hex.pl - Display hex values only for "Uncompressed entity body" sections from a tshark "hex and ASCII dump".
xtra/logalysis.sql - MySQL database schema. See 1.6 Logalysis "xtra/logalysis.sql" File.
xtra/logrotate.d/logalysis - Script to rotate log /var/log/logalysis/ack.log. Copy file to "/etc/logrotate.d/".
xtra/make/foremost-1.5.7-patch.tar.gz - Patched Foremost 1.5.7 source code. See A.1 Patching Foremost 1.5.7 Source Code.
xtra/make/tcpflow-1.2.6-patch.tar.gz - Patched tcpflow 1.2.6 source code. See A.2 Patching tcpflow 1.2.6 Source Code.
xtra/sbin/ - Copy these files to "/usr/local/sbin/".
xtra/sbin/dump_pcap.sh - tcpdump eth0 traffic to /var/log/pcaps/, creating a new pcap file every 5 minutes.
xtra/sbin/logalysis-mrt.pl - Server for remote messages to be displayed in the "REAL-TIME" section. See 7.3 Logalysis "xtra/sbin/logalysis-mrt.pl" File.
xtra/snort-sensor/snort_rule.php - Retrieve the Snort rule text from a Snort sensor running a web server.
xtra/sourcefire-dc/external_rule.cgi - Retrieve the Snort rule text from a Sourcefire Defense Center via HTTP.
xtra/sourcefire-dc/external_pcap.cgi - Retrieve a event pcap file from a Sourcefire Defense Centre via HTTP. See 5.2 Sourcefire IPS File.

1.5 Logalysis "common.php" File
===============================
Logalysis "common.php" file contains the following system settings:

  * $system - this is the name of the system user for jobs that have not been assigned to a user yet. It is also used as the first part of a job's reference number. If this is changed after the system has been running, job reference numbers will change automatically. However, job directories in the "files" directory will have to be renamed manually, this should be easy enough to script. Default value is:

    $system = "IDS";

  * $lbl_report - this is the displayed label for the boolean value of a job. Default value is:

    $lbl_report = "Reported";

  * $ref_pad - this is the number of digits to display in the last section of a reference number, padded with zeros. If this is changed after the system has been running, job reference numbers will change automatically. However, job directories in the "files" directory will have to be renamed manually, this should be easy enough to script. Default value is:

    $ref_pad = 3;

  * $show_files - this is an array containing the extensions of files to display in the browser when selected in the "FILES" section. Default value is:

    $show_files = array(".gif", ".jpg", ".png", ".txt");

  * $logalysis_db_host, $logalysis_db_user, $logalysis_db_pass, $logalysis_db_name - credentials to connect to the Logalysis MySQL database. Default values are:

    $logalysis_db_host = "localhost";
    $logalysis_db_user = "logalysis";
    $logalysis_db_pass = "P@55w0rd";
    $logalysis_db_name = "logalysis";

1.6 Logalysis "xtra/logalysis.sql" File
=======================================
Logalysis "xtra/logalysis.sql" file contains the MySQL database schema. Install using:

  mysql -u root -p < xtra/logalysis.sql

If the database needs to be purged and recreated, uncomment the commented commands in the "xtra/logalysis.sql" file, and run the above command again.

1.7 Logalysis "xtra/bin/add_job.pl" Script
==========================================
Logalysis "xtra/bin/add_job.pl" script reads from STDIN SQL INSERT commands starting with "INSERT INTO jobs ..." which are used to create new jobs. See example files "xtra/bin/sourcefire_events.pl", "xtra/bin/intrushield_events.pl" and "xtra/bin/snort_events.pl" for how to output the SQL INSERT command lines.

1.8 Logalysis "xtra/bin/check_snort.sh" Script
==============================================
Logalysis "xtra/bin/check_snort.sh" script is a shortcut for "snort_events.pl add | add_job.pl". Run as root first to create file "/var/log/snort.last", then use the following command to change permissions so any user can run the command:

  sudo chmod 666 /var/log/snort.last

To automate the checking process put the following line in your crontab (checks every 5 minutes):

  */5 * * * * /usr/local/bin/check_snort.sh

2. Operating
============

2.1 Tips
========
Note the following:

  * Only Mozilla Firefox and Google Chrome browsers are supported.
  * "SCRATCHPAD" is where logs or files can be generated that are not associated with a job, they can be moved to one.
  * Use the mouse scroll wheel to change a date/time field.
  * Buttons have a tooltip to display what they are for.
  * In the "REAL-TIME" section, the alert can have a tooltip that displays more information.
  * A "(D)" following a username or state name indicates the user or state has been disabled in the "SETTINGS" section.

2.2 Job Search
==============
When performing job searches, note the following:

  1. By selecting a user in the queue list, only their jobs will be searched.
  2. To return all jobs for a specific month, enter YYYYMM for search where YYYY is the year and MM is the month, e.g. "201311" (June 2013). Note 1.
  3. To return all jobs for a specific day, enter YYYYMMDD for search where YYYY is the year, MM is the month and DD is the day, e.g. "20130604" (4th June 2013). Note 1.
  4. To return a specific job, enter the digits of the job's reference number YYYYMMDD-NNNN for search, e.g. "20130604-0012". Note 1.
  5. To return all jobs that mention a job, enter the job's reference number SSS-YYYYMMDD-NNNN for search, e.g. "IDS-20130604-0012". Note 1.

3. Chart Plug-ins
=================

3.1 Chart Plug-in Files
=======================
When creating chart plug-ins two files are required to be placed in "plugins/chart/". Their extensions are:

  * ".search_chart.php" - this contains code to displays criteria to create a chart from.
  * ".generate_chart.php" - this contains code to display the chart. It connects to the data source to retrieve specific data, then uses the "fx/js/chart_gfx.js" file to draw the graph.

Global variables for ".search_chart.php" are:

  * $limit - number of events to return.
  * $start_time - start time of events.
  * $finish_time - finish time of events.

Use example chart plug-ins as templates.

4. Credential Plug-ins
======================

4.1 Credential Plug-in Files
============================
Credential plug-ins contain global variables used by other types of plug-ins. When creating credential plug-ins, placed them in "plugins/cred/" with the extension ".cred.php".

Use example credential plug-ins as templates.

5. File Plug-ins
================

5.1 File Plug-in Files
======================
When creating file plug-ins there are two types of files involved which are placed in "plugins/file/". Their extensions are:

  * ".search_file.php" - this contains code to displays criteria to create a file from.
  * ".generate_file.php" - this contains code to generate a file from a specific data source.

Global variables for ".search_file.php"are:

  * $search[1] - start time of data.
  * $search[2] - finish time of data.
  * $search[3] - used to identify specific data (e.g. source IP address).
  * $search[4] - used to identify specific data (e.g. source port).
  * $search[5] - used to identify specific data (e.g. target IP address).
  * $search[6] - used to identify specific data (e.g. target port).
  * $file_id - used to identify specific data.
  * $file_name - file name for generated file.

Use example file plug-ins as templates. More information on the example file plug-ins can be found in 5.2 - 5.4.

5.2 Sourcefire IPS File
=======================
Generated from Sourcefire Defense Center (DC) database table "packet_log". Field "packet_data" contains the raw payload of the packet. Locate the required "packet_data" using "sensor_id", "event_id" and "event_sec" values.

Sourcefire Field  Type
----------------  ----
sensor_id         INT(10) UNSIGNED
event_id          INT(10) UNSIGNED
event_sec         INT(10) UNSIGNED
pkt_sec           INT(10) UNSIGNED
pkt_usec          INT(10) UNSIGNED
linktype          INT(10) UNSIGNED
packet_data       BLOB

A script has been created "xtra/sourcefire-dc/external_pcap.cgi" which runs on the Sourcefire DC and returns the data as a pcap file, as the DC uses the "pkt_sec", "pkt_usec" and "linktype" to construct a pcap header. The "external_pcap.cgi" script is placed in "/var/sf/htdocs/" on the Sourcefire DC, and given the "sensor_id", "event_id" and "event_sec" values in the URL via HTTP.

5.3 IntruShield File
====================
Generated from McAfee IntruShield Network Security Manager database table "iv_packetlog". Field "packetData" contains the raw payload of the packet. Locate the required "packetData" using the "packetLogId" value.

IntruShield Field         Type
-----------------         ----
sensorId                  INT(11)
packetLogId               BIGINT(20)
packetLogGrpId            BIGINT(20)
packetLogType             CHAR(1)
packetLogSeq              INT(11)
lastReqByteStreamOffset   INT(11)
lastRespByteStreamOffset  INT(11)
markForDelete             CHAR(1)
vsaId                     INT(11)
vidsId                    INT(11)
slotId                    SMALLINT(6)
portId                    SMALLINT(6)
creationTime              TIMESTAMP
creationSeqNumber         INT(11)
sensorPacketlogUUID       BIGINT(20)
packetData                LONGBLOB

5.4 Snort File
==============
Generated from Snort database table "data". Field "data_payload" contains the raw payload of the packet in hexadecimal. Locate the required "data_payload" using "sid" and "cid" values.

Snort Field   Type
-----------   ----
sid           INT(10) UNSIGNED
cid           INT(10) UNSIGNED
data_payload  TEXT

6. Log Plug-ins
===============

6.1 Log Plug-in Types
=====================
When creating log plug-ins there are three types of files involved which are placed in "plugins/log/". Their extensions are:

  * ".search_log.php" - this contains code to displays criteria to create a log from.
  * ".generate_log.php" - this contains code to generate a log from a specific data source, and save it to the Logalysis database.
  * ".logalysis_log.php" - this contains code to retrieve the log from the Logalysis database.

Global variables for ".search_log.php" are:

  * $limit - number of events to return.
  * $search[1] - start time of events.
  * $search[2] - finish time of events.
  * $search[3] to $search[14] - strings used to identify specific events.
  * $search[15] - source IP address used to identify specific events.
  * $search[16] - source port used to identify specific events.
  * $search[17] - target IP address used to identify specific events.
  * $search[18] - target port used to identify specific events.

Use example log plug-ins as templates. More information on the example log plug-ins can be found in 6.2 - 6.8.

6.2 Logalysis Event Schema
==========================
Logalysis stores events using the following database schema:

Logalysis Field  Type
---------------  ----
time_1           DATETIME           $search[1]
time_2           DATETIME           $search[2]
num_1            BIGINT             $search[3]
num_2            BIGINT             $search[4]
num_3            BIGINT             $search[5]
num_4            BIGINT             $search[6]
num_5            BIGINT             $search[7]
char_1_64        VARCHAR(64)        $search[8]
char_2_64        VARCHAR(64)        $search[9]
char_3_255       VARCHAR(255)       $search[10]
char_4_255       VARCHAR(255)       $search[11]
char_5_255       VARCHAR(255)       $search[12]
char_6_255       VARCHAR(255)       $search[13]
protocol         VARCHAR(5)         $search[14]
source_ip        VARCHAR(39)        $search[15]
source_port      SMALLINT UNSIGNED  $search[16]
target_ip        VARCHAR(39)        $search[17]
target_port      SMALLINT UNSIGNED  $search[18]
data             BOOLEAN

The easiest way to create log plug-ins is to layout the required fields in a table, as demonstrated in the next few sections, to determine the Logalysis field store order (LFSO) and field retrieve order (LFRO).

The LFSO follows the database schema: time_1, time_2, num_1, num_2, num_3, num_4, num_5, char_1_64, char_2_64, char_3_255, char_4_255, char_5_255, char_6_255, protocol, source_ip, source_port, target_ip, target_port, data.

The LFRO is the order in which the fields are displayed on screen.

See the example log plug-ins for where to place the LFSO and LFRO.

6.3 Squid Access Logs
=====================
Generated from splitting lines in "/var/log/squid/access.log".

Column   Heading           Squid             Type    Logalysis
------   -------           -----             ----    ---------
$row[0]  Time              time              INT     time_1
$row[1]  Duration          duration          INT     num_1
$row[2]  Client IP         client            STRING  source_ip
$row[3]  Result/Status     result/status     STRING  char_1_64
$row[4]  Size              size              INT     num_2
$row[5]  Method            method            STRING  char_2_64
$row[6]  URL               url               STRING  char_3_255
$row[7]  Ident             ident             STRING  char_4_255
$row[8]  Hierarchy/Server  hierarchy/server  STRING  char_5_255
$row[9]  Type              type              STRING  char_6_255

LFSO:

  $row[0], NULL, $row[1], $row[4], NULL, NULL, NULL, $row[3], $row[5], $row[6], $row[7], $row[8], $row[9], NULL, $row[2], NULL, NULL, NULL, NULL

LFRO:

  time_1, num_1, source_ip, char_1_64, num_2, char_2_64, char_3_255, char_4_255, char_5_255, char_6_255

6.4 Apache2 Access Logs
=======================
Generated from splitting lines in "/var/log/apache2/access.log".

Column   Heading     Apache2     Type                    Logalysis
------   -------     -------     ----                    ---------
$row[0]  Time        time        INT                     time_1
$row[1]  Client IP   client      STRING                  source_ip
$row[2]  Ident       ident       STRING                  char_3_255
$row[3]  User        user        STRING                  char_1_64
$row[4]              timezone    <created during split>
$row[5]  URL         url         STRING                  char_4_255
$row[6]  Status      status      INT                     num_1
$row[7]  Size        size        INT                     num_2
$row[8]  Referer     referer     STRING                  char_5_255
$row[9]  User-Agent  user_agent  STRING                  char_6_255

LFSO:

  $row[0], NULL, $row[6], $row[7], NULL, NULL, NULL, $row[3], NULL, $row[2], $row[5], $row[8], $row[9], NULL, $row[1], NULL, NULL, NULL, NULL

LFRO:

  time_1, source_ip, char_3_255, char_1_64, char_4_255, num_1, num_2, char_5_255, char_6_255

6.5 Sourcefire IPS Logs
=======================
Generated from Sourcefire Defence Center database table "event".

Column    Heading         Sourcefire      SQL to get Value                               Type                  Logalysis
------    -------         ----------      ----------------                               ----                  ---------
$row[0]   Time            tv_sec                                                         INT(10) UNSIGNED      time_1
$row[1]   Priority        priority                                                       INT(10) UNSIGNED      num_1
$row[2]   Blocked         blocked                                                        TINYINT(1) UNSIGNED   char_1_64
$row[3]   Sensor          sensor_id       name FROM de_cache_de_config WHERE id                                char_3_255
$row[4]   Alert           sig_gen         msg FROM ids_event_msg_map WHERE gid                                 char_4_255
                          sig_gen                                                        INT(10) UNSIGNED      num_2
$row[5]   GID/SID         sig_id                                                         INT(10) UNSIGNED      num_3
$row[6]   Protocol        protocol                                                       TINYINT(3) UNSIGNED   protocol
$row[7]   Source IP       ip_src                                                         INT(10) UNSIGNED      source_ip
$row[8]   Port            sport_itype                                                    SMALLINT(5) UNSIGNED  source_port
$row[9]   Target IP       ip_dst                                                         INT(10) UNSIGNED      target_ip
$row[10]  Port            dport_icode                                                    SMALLINT(5) UNSIGNED  target_port
$row[11]  Classification  classification  description FROM ids_event_class_map WHERE id                        char_5_255
$row[12]  Impact          impact          impact_name FROM ids_impact_str WHERE impact                         char_2_64
$row[13]  EID             event_id                                                       INT(10) UNSIGNED      num_4
$data     Actions         tv_sec                                                         INT(10) UNSIGNED      data

LFSO:

  $row[0], NULL, $row[1], $row[4], $row[5], $row[13], NULL, $row[2], $row[12], $row[3], $row[4], $row[11], NULL, $row[6], $row[7], $row[8], $row[9], $row[10], $data

LFRO:

  time_1, num_1, char_1_64, char_3_255, char_4_255, num_2, num_3, protocol, source_ip, source_port, target_ip, target_port, char_5_255, char_2_64, num_4, data

6.6 Sourcefire RNA Logs
=======================
Generated from Sourcefire Defense Center database table "rna_flow_stats".

Column    Heading      Sourcefire      SQL to get Value                                                              Type                  Logalysis
------    -------      ----------      ----------------                                                              ----                  ---------
$row[0]   First        first_packet                                                                                  INT(10) UNSIGNED      time_1
$row[1]   Last         last_packet                                                                                   INT(10) UNSIGNED      time_2
$row[2]   Protocol     protocol                                                                                      TINYINT(3) UNSIGNED   protocol
$row[3]   Source IP    initiator                                                                                     INT(10) UNSIGNED      source_ip
$row[4]   Port         initiator_port                                                                                SMALLINT(5) UNSIGNED  source_port
$row[5]   Target IP    responder                                                                                     INT(10) UNSIGNED      target_ip
$row[6]   Port         responder_port                                                                                SMALLINT(5) UNSIGNED  target_port
$row[7]   Packets TX   packets_sent                                                                                  INT(10) UNSIGNED      num_1
$row[8]   Packets RX   packets_recv                                                                                  INT(10) UNSIGNED      num_2
$row[9]   Bytes TX     bytes_sent                                                                                    INT(10) UNSIGNED      num_3
$row[10]  Bytes RX     bytes_recv                                                                                    INT(10) UNSIGNED      num_4
$row[11]  Application  clnt_app_fp_id  product_str FROM rna_client_application_fingerprint_str WHERE clnt_app_fp_id                        char_3_255
$row[12]  Version      version                                                                                       VARCHAR(255)          char_4_255
$row[13]  Service      service_id      service_name FROM rna_service_list WHERE service_id                                                 char_5_255

LFSO:

  $row[0], $row[1], $row[7], $row[8], $row[9], $row[10], NULL, NULL, NULL, $row[11], $row[12], $row[13], NULL, $row[2], $row[3], $row[4], $row[5], $row[6], NULL

LFRO:

  time_1, time_2, protocol, source_ip, source_port, target_ip, target_port, num_1, num_2, num_3, num_4, char_3_255, char_4_255, char_5_255

6.7 IntruShield Logs
====================
Generated from McAfee IntruShield Network Security Manager database table "iv_alert".

Column    Heading      IntruShield         SQL to get Value                                            Type         Logalysis
------    -------      -----------         ----------------                                            ----         ---------
$row[0]   Time         creationTime                                                                    TIMESTAMP    time_1
$row[1]   Priority     severity                                                                        TINYINT(4)   num_1
$row[2]   Result       resultSetValue      displayableName FROM iv_result_set WHERE resultSetValue                  char_1_64
$row[3]   Sensor       sensorId            name FROM iv_sensor WHERE sensor_id                                      char_3_255
$row[4]   Detection    detectionMechanism  displayableName FROM iv_detection WHERE detectionMechanism               char_2_64
$row[5]   Alert        direction           name FROM iv_attack WHERE id                                TINYINT(4)   char_4_255
$row[6]   AID          attackIdRef                                                                     CHAR(20)     num_2
$row[7]   Protocol     networkProtocolId                                                               SMALLINT(6)  protocol
$row[8]   Source IP    sourceIPAddr                                                                    CHAR(32)     source_ip
$row[9]   Port         sourcePort                                                                      INT(11)      source_port
$row[10]  Target IP    targetIPAddr                                                                    CHAR(32)     target_ip
$row[11]  Port         targetPort                                                                      INT(11)      target_port
$row[12]  Category     categoryId          displayableName FROM iv_categories WHERE categoryId                      char_5_255
$row[13]  Subcategory  subCategoryId       display_name FROM iv_subcategories WHERE idnum                           char_6_255
$row[14]  EID          uuid                                                                            BIGINT(20)   num_3
$row[15]               packetLogId                                                                     BIGINT(20)   num_4
$data     Data                                                                                                      data

LFSO:

  $row[0], NULL, $row[1], $row[6], $row[14], $row[15], NULL, $row[2], $row[4], $row[3], $row[5], $row[12], $row[13], $row[7], $row[8], $row[9], $row[10], $row[11], $row[15]

LFRO:

  time_1, num_1, char_1_64, char_3_255, char_2_64, char_4_255, num_2, protocol, source_ip, source_port, target_ip, target_port, char_5_255, char_6_255, num_3, num_4

6.8 Snort Logs
==============
Generated from Snort database table "event".

Column    Heading         Snort      SQL to get Value                                                              Type                  Logalysis
------    -------         -----      ----------------                                                              ----                  ---------
$row[0]   Time            timestamp                                                                                DATETIME              time_1
$row[1]   Priority        signature  sig_priority FROM signature WHERE sig_id                                      INT(10) UNSIGNED      num_1
$row[2]   Sensor          sid        hostname FROM sensor WHERE sid                                                TEXT                  char_3_255
$row[3]   Alert           signature  sig_name FROM signature WHERE sig_id                                          VARCHAR(255)          char_4_255
$row[4]   GID/SID         signature  sig_gid FROM signature WHERE sig_id                                           INT(10) UNSIGNED      num_2
$row[5]                   signature  sig_sid FROM signature WHERE sig_id                                           INT(10) UNSIGNED      num_3
$row[6]   Protocol        cid        ip_proto FROM iphdr WHERE sid AND cid                                         TINYINT(3) UNSIGNED   protocol
$row[7]   Source IP       cid        ip_src FROM iphdr WHERE sid AND cid                                           INT(10) UNSIGNED      source_ip
$row[8]   Port            cid        tcp/udp_sport FROM tcp/udphdr WHERE sid AND cid                               SMALLINT(5) UNSIGNED  source_port
$row[9]   Target IP       cid        ip_dst FROM iphdr WHERE sid AND cid                                           INT(10) UNSIGNED      target_ip
$row[10]  Port            cid        tcp/udp_dport FROM tcp/udphdr WHERE sid AND cid                               SMALLINT(5) UNSIGNED  target_port
$row[11]  Classification  signature  sig_class_name FROM sig_class WHERE sig_class_id FROM signature WHERE sig_id  VARCHAR(60)           char_1_64
$row[12]  EID             cid                                                                                      INT(10) UNSIGNED      num_4
$data     Data                                                                                                                           data

LFSO:

  $row[0], NULL, $row[1], $row[4], $row[5], $row[12], NULL, $row[11], NULL, $row[2], $row[3], NULL, NULL, $row[6], $row[7], $row[8], $row[9], $row[10], $data

LFRO:

  time_1, num_1, char_3_255, char_4_255, num_2, num_3, protocol, source_ip, source_port, target_ip, target_port, char_1r_1_64, num_4, data

7. Real-time Plug-ins
=====================

7.1 Real-time Plug-in Type
==========================
Real-time plug-ins list current events from a data source. When creating real-time plug-ins, place them in "plugins/realtime/" with the extension ".realtime.php". The plugin will output table rows (<TR>) with <TD> tags for the following fields:

  * Priority (1 H, 2 M or 3 L)
  * Time (YYYY-MM-DD HH:MM:SS)
  * Type
  * Alert
  * Source
  * Number (#)
  * Actions

Use example real-time plug-ins as templates.

7.2 Real-time Messages
======================
To have a message displayed in the "REAL-TIME" section, place a file in "files/RT_Messages/". The filename will be used as the "Alert" field (with "_" replaced by " "). The first line of file is in the format "A*B*C*D*E*\n", where:

  * A is a priority - "1 H", "2 M" or "3 L".
  * B is a time in seconds from the epoch.
  * C is the tooltip of the "Alert" field.
  * D is the source of the alert.
  * E is the count of events.

Further lines in the file are related to what is displayed in the "Actions" field. They are in the format "A*B*C*\n", and translate to a HTML anchor:

  <a class='action' href='A' target='B'>C</a>

7.3 Logalysis "xtra/sbin/logalysis-mrt.pl" Script
=================================================
Loglysis "xtra/sbin/logalysis-mrt.pl" script is a server for remote messages to be displayed in the "REAL-TIME" section. Execute the script as root where Logalysis is installed. Send a string to the server on TCP port 8 in the format "logalysis;A;B;C;D;E;F", where:

  * A is the filename, which will be used as the "Alert" field (with "_" replaced by " ").
  * B is a priority - "1 H", "2 M" or "3 L".
  * C is a time in seconds from the epoch.
  * D is the tooltip of the "Alert" field.
  * E is the source of the alert.
  * F is the count of events.

Below is an example of how to send a message using netcat:

  echo -n "logalysis;Example_Alert;2 M;1369730087;Extra Info;127.0.0.1;2" | nc <SERVER IP> 8

8. Report Plug-ins
==================

8.1 Report Plug-in Type
=======================
When creating report plug-ins two files are required to be placed in "plugins/report/". Their extensions are:

  * ".search_report.php" - this contains code to displays criteria to create a report from.
  * ".generate_report.php" - this contains code to display the report.

Global variables for ".search_report.php" are:

  * $start_time - start time of events.
  * $finish_time - finish time of events.

Use example report plug-ins as templates. Possible to create the fixed portion of your report in MS Word and save it as HTML, then add it to the report plug-in.

9. pcap Plug-ins
================

9.1 pcap Plug-in Type
=====================
pcap plug-ins are Bash scripts which perform a specific action on a given pcap file. When creating pcap plug-ins, place them in "plugins/pcap/" with the extension ".pcap.sh".

Use example pcap plug-ins as templates.

10. Note and Change Templates
=============================

10.1 Note Templates
===================
Note templates are text files. When creating note templates, place them in "plugins/note/" using the filename format "<NOTE TYPE>.<NOTE NAME>.note.txt". NOTE NAME is displayed in the new note menu. NOTE TYPE is displayed in the note type field above the template text. To not display the note type field use "note" for NOTE TYPE.

See example note templates for more information.

10.2 Change Templates
=====================
Logalysis has a simple change management system that allows you to define and step through job states, e.g. Change Details -> Peer Review -> Implementation -> Verification. Change Details is hard coded as the first change step, give other steps a position number > 100 when defining the state, e.g. Peer Review 101, Implementation 102, Verfication 103. To raise a change for a job, select the "Raise Change" button on the job's details page, this button will change to "Complete" to complete the change steps.

Change templates are text files. When creating change details templates, place them in "plugins/note/" using the filename format "change_details.<CHANGE TYPE>.change.txt". CHANGE TYPE is displayed in the change type menu when raising a change. When creating change step templates, place them in "plugins/note/" using the filename format "<STEP NAME>.change.note.txt", e.g. peer_review.change.note.text.

See example change templates for more information.

Appendix A - Patching Source Code
=================================

A.1 Patching Foremost 1.5.7 Source Code
=======================================
Make the following changes to the Foremost source before compiling:

  1. In file "main.c" comment out the following lines:

    if (create_output_directory(s))
      fatal_error(s, "Unable to open output directory");

    if (!get_mode(s, mode_write_audit))
    {
      create_sub_dirs(s);
    }

    if (open_audit_file(s))
      fatal_error(s, "Can't open audit file");

    if (close_audit_file(s))
    {

    /* Hells bells. This is bad, but really, what can we do about it?
       Let's just report the error and try to get out of here! */
       print_error(s, AUDIT_FILE_NAME, "Error closing audit file");
    }

  2. In file "dir.c" change the following text:

    snprintf(fn,
      MAX_STRING_LENGTH,
      "%s/%s/%0*llu.%s", ---> "%s/%0*llu.%s",
      s->output_directory,
      needle->suffix, ---> //needle->suffix,
      8,

    snprintf(fn,
      MAX_STRING_LENGTH - 1,
      "%s/%s/%0*llu_%d.%s", ---> "%s/%0*llu_%d.%s",
      s->output_directory,
      needle->suffix, ---> //needle->suffix,
      8,

  3. In file "state.c" comment out the following lines:

    va_list argp;
    va_start(argp, format);

    if (get_mode(s, mode_verbose)) {
      print_message(s, format, argp);
      va_end(argp);
      va_start(argp, format);
    }

    vfprintf(s->audit_file, format, argp);
    va_end(argp);

    fprintf(s->audit_file, "%s", NEWLINE);
    fflush(stdout);

Compile source code using command "make". Install software using command "sudo make install".

A.2 Patching tcpflow 1.2.6 Source Code
======================================
Make the following changes to the tcpflow source before compiling:

  1. In file "src/main.cpp" change the following text:

    bool opt_all = true; ---> bool opt_all = false;

    case 'c':
      console_only = 1;  DEBUG(10) ("printing packets to console only");
      strip_nonprint = 1;  DEBUG(10) ("converting non-printable characters to '.'"); ---> suppress_header = 1;  DEBUG(10) ("packet header dump suppressed");
      break;

  2. In file "src/tcpip.cpp" comment out the following lines:

    putchar('\n');

Compile source code using commands "./configure" then "make". Install software using command "sudo make install".

Appendix B - Data Source Access
===============================

B.1 Linux Log File Access
=========================
If retrieving data from Linux log files the following steps are required (e.g. Apache2 logs):

  1. Allow access to the directory where logs are stored:

    chmod 755 /var/log/apache2

  2. Allow access to the log files that already exist:

    chmod 644 /var/log/apache2/access.log
    chmod 644 /var/log/apache2/access.log.1
    chmod 644 /var/log/apache2/access.log.2.gz

  3. Change the "create" line in "/etc/logrotate.d/apache2" to allow access to new logs that are created:

    create 644 root adm

B.2 Sourcefire Defence Center (DC) Access
=========================================
If retrieving data from a Sourcefire DC the following steps are required:

  1. Gain access via ssh to the Sourcefire DC:

    ssh admin@<SOURCEFIRE DC>  (DEFAULT PASSWORD: Sourcefire)

  2. Add the following line to "/etc/sysconfig/iptables" (sudo vi, default password: Sourcefire) to allow remote access to the Sourcefire DC database:

    -A INPUT -i eth0 -p tcp -m tcp --dport 3306 -j ACCEPT  (AFTER: #stop SSL SSH SNMP PORTS INPUT BLOCK)

  3. Restart iptables:

    sudo /etc/rc.d/init.d/iptables restart  (DEFAULT PASSWORD: Sourcefire)

  4. Login to the Sourcefire DC database:

    mysql -u root -p  (DEFAULT PASSWORD: admin)

  5. Grant access to the user "logalysis" at host, e.g. "123.123.123.123" (or "123.123.123.%" if a network is required), using password, e.g. "P@55w0rd":

    GRANT USAGE ON sfsnort.* TO 'logalysis'@'123.123.123.123' IDENTIFIED BY 'P@55w0rd';

  6. Grant access to specific Sourcefire IPS tables to the user "logalysis" at host, e.g. "123.123.123.123" (or "123.123.123.%" if a network is required):

    GRANT SELECT, UPDATE ON sfsnort.event TO 'logalysis'@'123.123.123.123';
    GRANT SELECT ON sfsnort.de_cache_de_config TO 'logalysis'@'123.123.123.123';
    GRANT SELECT ON sfsnort.ids_event_msg_map TO 'logalysis'@'123.123.123.123';
    GRANT SELECT ON sfsnort.ids_event_class_map TO 'logalysis'@'123.123.123.123';
    GRANT SELECT ON sfsnort.ids_impact_str TO 'logalysis'@'123.123.123.123';
    GRANT SELECT ON sfsnort.packet_log TO 'logalysis'@'123.123.123.123';

  7. Grant access to specific Sourcefire RNA tables to the user "logalysis" at host, e.g. "123.123.123.123" (or "123.123.123.%" if a network is required):

    GRANT SELECT ON sfsnort.rna_flow_stats TO 'logalysis'@'123.123.123.123';
    GRANT SELECT ON sfsnort.rna_client_application_fingerprint_str TO 'logalysis'@'123.123.123.123';
    GRANT SELECT ON sfsnort.rna_service_list TO 'logalysis'@'123.123.123.123';

When performing an upgrade of the Sourcefire DC it is recommended to remove the above access using the following steps (when reinserting this will also confirm that table names have not changed):

  1. Gain access via ssh to the Sourcefire DC:

    ssh admin@<SOURCEFIRE DC>  (DEFAULT PASSWORD: Sourcefire)

  2. Login to the Sourcefire DC database:

    mysql -u root -p  (DEFAULT PASSWORD: admin)

  3. Issue the following commands to delete access:

    USE mysql;
    DELETE FROM user WHERE User = 'logalysis';
    DELETE FROM tables_priv WHERE User = 'logalysis';

B.3 McAfee IntruShield Network Security Manager (NSM) Access
============================================================
If retrieving data from a IntruShield NSM the following steps are required:

  1. Login to the IntruShield NSM database:

    "\Program Files\McAfee\Network Security Manager\MySQL\bin\mysql" -u root -p

  2. Grant access to the user "logalysis" at host, e.g. "123.123.123.123" (or "123.123.123.%" if a network is required), using password, e.g. "P@55w0rd":

    GRANT USAGE ON lf.* TO 'logalysis'@'123.123.123.123' IDENTIFIED BY 'P@55w0rd';

  3. Grant access to specific tables to the user "logalysis" at host, e.g. "123.123.123.123" (or "123.123.123.%" if a network is required):

    GRANT SELECT, UPDATE ON lf.iv_alert TO 'logalysis'@'123.123.123.123';
    GRANT SELECT ON lf.iv_result_set TO 'logalysis'@'123.123.123.123';
    GRANT SELECT ON lf.iv_sensor TO 'logalysis'@'123.123.123.123';
    GRANT SELECT ON lf.iv_direction TO 'logalysis'@'123.123.123.123';
    GRANT SELECT ON lf.iv_detection TO 'logalysis'@'123.123.123.123';
    GRANT SELECT ON lf.iv_attack TO 'logalysis'@'123.123.123.123';
    GRANT SELECT ON lf.iv_categories TO 'logalysis'@'123.123.123.123';
    GRANT SELECT ON lf.iv_subcategories TO 'logalysis'@'123.123.123.123';
    GRANT SELECT ON lf.iv_packetlog TO 'logalysis'@'123.123.123.123';

When performing an upgrade of the IntruShield NSM it is recommended to remove the above access using the following steps (when reinserting this will also confirm that table names have not changed):

  1. Login to the IntruShield NSM database:

    "\Program Files\McAfee\Network Security Manager\MySQL\bin\mysql" -u root -p

  2. Issue the following commands to delete access:

    USE mysql;
    DELETE FROM user WHERE User = 'logalysis';
    DELETE FROM tables_priv WHERE User = 'logalysis';

==============================
Copyright 2012-2016 Del Castle