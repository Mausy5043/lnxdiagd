#!/bin/bash

# Pull data from MySQL server and graph them.

datastore="/tmp/lnxdiagd/mysql"

if [ ! -d "$datastore" ]; then
  mkdir -p "$datastore"
fi

interval="INTERVAL 8 DAY "
host=$(hostname)

pushd "$HOME/lnxdiagd" >/dev/null
  mysql -h sql.lan --skip-column-names -e "USE domotica; SELECT * FROM systemp where (sample_time >=NOW() - $interval) AND (host = '$host');" | sed 's/\t/;/g;s/\n//g' > "$datastore/sql11w.csv"
  mysql -h sql.lan --skip-column-names -e "USE domotica; SELECT * FROM sysload where (sample_time >=NOW() - $interval) AND (host = '$host');" | sed 's/\t/;/g;s/\n//g' > "$datastore/sql12w.csv"
  mysql -h sql.lan --skip-column-names -e "USE domotica; SELECT * FROM sysnet  where (sample_time >=NOW() - $interval) AND (host = '$host');" | sed 's/\t/;/g;s/\n//g' > "$datastore/sql13w.csv"
  mysql -h sql.lan --skip-column-names -e "USE domotica; SELECT * FROM sysmem  where (sample_time >=NOW() - $interval) AND (host = '$host');" | sed 's/\t/;/g;s/\n//g' > "$datastore/sql14w.csv"
  mysql -h sql.lan --skip-column-names -e "USE domotica; SELECT * FROM syslog  where (sample_time >=NOW() - $interval) AND (host = '$host');" | sed 's/\t/;/g;s/\n//g' > "$datastore/sql15w.csv"

  #http://www.sitepoint.com/understanding-sql-joins-mysql-database/
  #mysql -h sql.lan --skip-column-names -e "USE domotica; SELECT ds18.sample_time, ds18.sample_epoch, ds18.temperature, wind.speed FROM ds18 INNER JOIN wind ON ds18.sample_epoch = wind.sample_epoch WHERE (ds18.sample_time) >=NOW() - INTERVAL 1 MINUTE;" | sed 's/\t/;/g;s/\n//g' > $datastore/sql2c.csv
  if [ "$host" == "boson" ]; then
    mysql -h sql.lan --skip-column-names < data19w.sql | sed 's/\t/;/g;s/\n//g' > "$datastore/sql19w.csv"
  fi

  datastore="/tmp/lnxdiagd/mysql4python"

  if [ ! -d "${datastore}" ]; then
    mkdir -p "${datastore}"
  fi

  # # Get week data for system temperature (systemp; graph11)
  # divider=14400
  # mysql -h sql.lan --skip-column-names -e \
  # "USE domotica; \
  #  SELECT MIN(sample_time), MIN(temperature), AVG(temperature), MAX(temperature) \
  #  FROM systemp \
  #  WHERE (sample_time >= NOW() - ${interval}) AND (host = '${host}') \
  #  GROUP BY (sample_epoch DIV ${divider});" \
  # | sed 's/\t/;/g;s/\n//g' > "${datastore}/sql11w.csv"
  #
  # # Get week data for system load (sysload; graph12)
  # mysql -h sql.lan --skip-column-names -e \
  # "USE domotica; \
  #  SELECT MIN(sample_time), AVG(load5min), \
  #         AVG(user),  AVG(system),  AVG(waiting) \
  #  FROM sysload \
  #  WHERE (sample_time >= NOW() - ${interval}) AND (host = '${host}') \
  #  GROUP BY (sample_epoch DIV ${divider});" \
  # | sed 's/\t/;/g;s/\n//g' > "${datastore}/sql12w.csv"
popd >/dev/null
