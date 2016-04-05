#!/bin/bash

# Pull data from MySQL server and graph them.

#sleep 3

LOCAL=$(date)
LOCALSECONDS=$(date -d "$LOCAL" +%s)
UTC=$(date -u -d "$LOCAL" +"%Y-%m-%d %H:%M:%S")  #remove timezone reference
UTCSECONDS=$(date -d "$UTC" +%s)
UTCOFFSET=$(($LOCALSECONDS-$UTCSECONDS))

interval="INTERVAL 50 HOUR "
host=$(hostname)

pushd $HOME/lnxdiagd >/dev/null
  mysql -h sql.lan --skip-column-names -e "USE domotica; SELECT * FROM systemp where (sample_time >=NOW() - $interval) AND (host = '$host');" | sed 's/\t/;/g;s/\n//g' > /tmp/sql11.csv
  mysql -h sql.lan --skip-column-names -e "USE domotica; SELECT * FROM sysload where (sample_time >=NOW() - $interval) AND (host = '$host');" | sed 's/\t/;/g;s/\n//g' > /tmp/sql12.csv
  mysql -h sql.lan --skip-column-names -e "USE domotica; SELECT * FROM sysnet where (sample_time >=NOW() - $interval) AND (host = '$host');" | sed 's/\t/;/g;s/\n//g' > /tmp/sql13.csv
  mysql -h sql.lan --skip-column-names -e "USE domotica; SELECT * FROM sysmem where (sample_time >=NOW() - $interval) AND (host = '$host');" | sed 's/\t/;/g;s/\n//g' > /tmp/sql14.csv
  mysql -h sql.lan --skip-column-names -e "USE domotica; SELECT * FROM syslog where (sample_time >=NOW() - $interval) AND (host = '$host');" | sed 's/\t/;/g;s/\n//g' > /tmp/sql15.csv

  #http://www.sitepoint.com/understanding-sql-joins-mysql-database/
  #mysql -h sql.lan --skip-column-names -e "USE domotica; SELECT ds18.sample_time, ds18.sample_epoch, ds18.temperature, wind.speed FROM ds18 INNER JOIN wind ON ds18.sample_epoch = wind.sample_epoch WHERE (ds18.sample_time) >=NOW() - INTERVAL 1 MINUTE;" | sed 's/\t/;/g;s/\n//g' > /tmp/sql2c.csv

  #touch /tmp/bonediagd/graph.lock
  gnuplot -e "utc_offset='${UTCOFFSET}'" ./graph11.gp
  #gnuplot -e "utc_offset='${UTCOFFSET}'" ./graph23.gp
  #gnuplot -e "utc_offset='${UTCOFFSET}'" ./graph24.gp
  #gnuplot -e "utc_offset='${UTCOFFSET}'" ./graph25.gp

  #rm /tmp/bonediagd/graph.lock
popd >/dev/null
