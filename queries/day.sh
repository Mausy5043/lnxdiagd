#!/bin/bash

# Pull DAILY data from MySQL server and graph them.

pushd "$HOME/lnxdiagd" >/dev/null || exit 1

  # shellcheck disable=SC1091
  source ./sql-includes || exit

  #sleep $(echo $RANDOM/555 |bc)

  mysql -h sql --skip-column-names -e "USE domotica; SELECT * FROM systemp where (sample_time >=NOW() - ${D_INTERVAL}) AND (host = '${HOST}');" | sed 's/\t/;/g;s/\n//g' > "${DATASTORE}/sql11d.csv"
  mysql -h sql --skip-column-names -e "USE domotica; SELECT * FROM sysload where (sample_time >=NOW() - ${D_INTERVAL}) AND (host = '${HOST}');" | sed 's/\t/;/g;s/\n//g' > "${DATASTORE}/sql12d.csv"
  mysql -h sql --skip-column-names -e "USE domotica; SELECT * FROM sysnet  where (sample_time >=NOW() - ${D_INTERVAL}) AND (host = '${HOST}');" | sed 's/\t/;/g;s/\n//g' > "${DATASTORE}/sql13d.csv"
  mysql -h sql --skip-column-names -e "USE domotica; SELECT * FROM sysmem  where (sample_time >=NOW() - ${D_INTERVAL}) AND (host = '${HOST}');" | sed 's/\t/;/g;s/\n//g' > "${DATASTORE}/sql14d.csv"
  mysql -h sql --skip-column-names -e "USE domotica; SELECT * FROM syslog  where (sample_time >=NOW() - ${D_INTERVAL}) AND (host = '${HOST}');" | sed 's/\t/;/g;s/\n//g' > "${DATASTORE}/sql15d.csv"

  #http://www.sitepoint.com/understanding-sql-joins-mysql-database/
  #mysql -h sql --skip-column-names -e "USE domotica; SELECT ds18.sample_time, ds18.sample_epoch, ds18.temperature, wind.speed FROM ds18 INNER JOIN wind ON ds18.sample_epoch = wind.sample_epoch WHERE (ds18.sample_time) >=NOW() - D_INTERVAL 1 MINUTE;" | sed 's/\t/;/g;s/\n//g' > /tmp/sql2c.csv

  if [ "${HOST}" == "boson" ]; then
    mysql -h sql --skip-column-names  < data19d.sql | sed 's/\t/;/g;s/\n//g' > "${DATASTORE}/sql19d.csv"
  fi

  # Get day data for system temperature (systemp; graph11)
  mysql -h sql --skip-column-names -e             \
  "USE domotica;                                  \
   SELECT MIN(sample_time),                       \
          MIN(temperature),                       \
          AVG(temperature),                       \
          MAX(temperature)                        \
    FROM systemp                                  \
    WHERE (sample_time >= NOW() - ${D_INTERVAL})  \
      AND (sample_time <= NOW() - ${H_INTERVAL})  \
      AND (host = '${HOST}')                      \
    GROUP BY (sample_epoch DIV ${D_DIVIDER});"    \
  | sed 's/\t/;/g;s/\n//g' > "${DATASTORE4}/sql11d.csv"

  # Get day data for system load (sysload; graph12)
  mysql -h sql --skip-column-names -e             \
  "USE domotica;                                  \
   SELECT MIN(sample_time),                       \
          AVG(load5min),                          \
          AVG(user),                              \
          AVG(system),                            \
          AVG(waiting)                            \
    FROM sysload                                  \
    WHERE (sample_time >= NOW() - ${D_INTERVAL})  \
      AND (sample_time <= NOW() - ${H_INTERVAL})  \
      AND (host = '${HOST}')                      \
    GROUP BY (sample_epoch DIV ${D_DIVIDER});"    \
  | sed 's/\t/;/g;s/\n//g' > "${DATASTORE4}/sql12d.csv"

popd >/dev/null
