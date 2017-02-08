#!/bin/bash

# Pull data from MySQL server and graph them.

datastore="/tmp/lnxdiagd/mysql"

if [ ! -d "$datastore" ]; then
  mkdir -p "$datastore"
fi

interval="INTERVAL 70 MINUTE "
host=$(hostname)

sleep $(echo $RANDOM/555 |bc)

pushd "$HOME/lnxdiagd" >/dev/null
  mysql -h sql.lan --skip-column-names -e "USE domotica; SELECT * FROM systemp where (sample_time >=NOW() - $interval) AND (host = '$host');" | sed 's/\t/;/g;s/\n//g' > "$datastore/sql11h.csv"
  mysql -h sql.lan --skip-column-names -e "USE domotica; SELECT * FROM sysload where (sample_time >=NOW() - $interval) AND (host = '$host');" | sed 's/\t/;/g;s/\n//g' > "$datastore/sql12h.csv"
  mysql -h sql.lan --skip-column-names -e "USE domotica; SELECT * FROM sysnet  where (sample_time >=NOW() - $interval) AND (host = '$host');" | sed 's/\t/;/g;s/\n//g' > "$datastore/sql13h.csv"
  mysql -h sql.lan --skip-column-names -e "USE domotica; SELECT * FROM sysmem  where (sample_time >=NOW() - $interval) AND (host = '$host');" | sed 's/\t/;/g;s/\n//g' > "$datastore/sql14h.csv"
  mysql -h sql.lan --skip-column-names -e "USE domotica; SELECT * FROM syslog  where (sample_time >=NOW() - $interval) AND (host = '$host');" | sed 's/\t/;/g;s/\n//g' > "$datastore/sql15h.csv"

  #http://www.sitepoint.com/understanding-sql-joins-mysql-database/
  #mysql -h sql.lan --skip-column-names -e "USE domotica; SELECT ds18.sample_time, ds18.sample_epoch, ds18.temperature, wind.speed FROM ds18 INNER JOIN wind ON ds18.sample_epoch = wind.sample_epoch WHERE (ds18.sample_time) >=NOW() - INTERVAL 1 MINUTE;" | sed 's/\t/;/g;s/\n//g' > $datastore/sql2c.csv
  if [ "$host" == "boson" ]; then
    mysql -h sql.lan --skip-column-names  < data19h.sql | sed 's/\t/;/g;s/\n//g' > "$datastore/sql19h.csv"
  fi

  datastore="/tmp/lnxdiagd/mysql4python"

  if [ ! -d "${datastore}" ]; then
    mkdir -p "${datastore}"
  fi

  # Get hour  for system temperature (systemp; graph11)
  # DIV t : t/100 minutes
  divider=100
  mysql -h sql.lan --skip-column-names -e \
  "USE domotica; \
   SELECT MIN(sample_time), AVG(temperature) \
   FROM systemp \
   WHERE (sample_time >= NOW() - ${interval}) \
   GROUP BY (sample_time) DIV ${divider};" \
  | sed 's/\t/;/g;s/\n//g' > "${datastore}/sql11h.csv"

popd >/dev/null
