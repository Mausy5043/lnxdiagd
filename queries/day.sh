#!/bin/bash

# Pull DAILY data from MySQL server and graph them.

pushd "$HOME/lnxdiagd/queries/" >/dev/null || exit 1

  # shellcheck disable=SC1091
  source ./sql-includes || exit

  #sleep $(echo $RANDOM/555 |bc)

  #time mysql -h sql --skip-column-names -e "USE domotica; SELECT * FROM systemp where (sample_time >=NOW() - ${D_INTERVAL}) AND (sample_time <= NOW() - ${DH_INTERVAL}) AND (host = '${HOST}');" | sed 's/\t/;/g;s/\n//g' > "${DATASTORE}/sql11d.csv"
  #time mysql -h sql --skip-column-names -e "USE domotica; SELECT * FROM sysload where (sample_time >=NOW() - ${D_INTERVAL}) AND (sample_time <= NOW() - ${DH_INTERVAL}) AND (host = '${HOST}');" | sed 's/\t/;/g;s/\n//g' > "${DATASTORE}/sql12d.csv"
  #time mysql -h sql --skip-column-names -e "USE domotica; SELECT * FROM sysnet  where (sample_time >=NOW() - ${D_INTERVAL}) AND (sample_time <= NOW() - ${DH_INTERVAL}) AND (host = '${HOST}');" | sed 's/\t/;/g;s/\n//g' > "${DATASTORE}/sql13d.csv"
  #time mysql -h sql --skip-column-names -e "USE domotica; SELECT * FROM sysmem  where (sample_time >=NOW() - ${D_INTERVAL}) AND (sample_time <= NOW() - ${DH_INTERVAL}) AND (host = '${HOST}');" | sed 's/\t/;/g;s/\n//g' > "${DATASTORE}/sql14d.csv"
  #time mysql -h sql --skip-column-names -e "USE domotica; SELECT * FROM syslog  where (sample_time >=NOW() - ${D_INTERVAL}) AND (sample_time <= NOW() - ${DH_INTERVAL}) AND (host = '${HOST}');" | sed 's/\t/;/g;s/\n//g' > "${DATASTORE}/sql15d.csv"

  #http://www.sitepoint.com/understanding-sql-joins-mysql-database/
  #mysql -h sql --skip-column-names -e "USE domotica; SELECT ds18.sample_time, ds18.sample_epoch, ds18.temperature, wind.speed FROM ds18 INNER JOIN wind ON ds18.sample_epoch = wind.sample_epoch WHERE (ds18.sample_time) >=NOW() - D_INTERVAL 1 MINUTE;" | sed 's/\t/;/g;s/\n//g' > /tmp/sql2c.csv

  #if [ "${HOST}" == "boson" ]; then
  #  time mysql -h sql --skip-column-names  < data19d.sql | sed 's/\t/;/g;s/\n//g' > "${DATASTORE}/sql19d.csv"
  #fi

  # Get day data for system temperature (systemp; graph11)
	echo -n "11"
  time mysql -h sql --skip-column-names -e             \
  "USE domotica;                                  \
   SELECT MIN(sample_epoch),                      \
          MIN(temperature),                       \
          AVG(temperature),                       \
          MAX(temperature)                        \
    FROM systemp                                  \
    WHERE (sample_time >= NOW() - ${D_INTERVAL})  \
      AND (sample_time <= NOW() - ${DH_INTERVAL}) \
      AND (host = '${HOST}')                      \
    GROUP BY (sample_epoch DIV ${D_DIVIDER});"    \
  | sed 's/\t/;/g;s/\n//g' > "${DATASTORE}/sql11d.csv"

  # Get day data for system load (sysload; graph12)
	echo -n "12"
	time mysql -h sql --skip-column-names -e             \
  "USE domotica;                                  \
   SELECT MIN(sample_epoch),                      \
          AVG(load5min),                          \
          AVG(user),                              \
          AVG(system),                            \
          AVG(waiting),                           \
          AVG(idle)                               \
    FROM sysload                                  \
    WHERE (sample_time >= NOW() - ${D_INTERVAL})  \
      AND (sample_time <= NOW() - ${DH_INTERVAL}) \
      AND (host = '${HOST}')                      \
    GROUP BY (sample_epoch DIV ${D_DIVIDER});"    \
  | sed 's/\t/;/g;s/\n//g' > "${DATASTORE}/sql12d.csv"

  # Get day data for system network load (sysnet; graph13)
	echo -n "13"
  time mysql -h sql --skip-column-names -e             \
  "USE domotica;                                  \
   SELECT MIN(sample_epoch),                      \
          MIN(etIn),                              \
          MAX(etIn),                              \
          MIN(etOut),                             \
          MAX(etOut)                              \
    FROM sysnet                                   \
    WHERE (sample_time >= NOW() - ${D_INTERVAL})  \
      AND (sample_time <= NOW() - ${DH_INTERVAL}) \
      AND (host = '${HOST}')                      \
    GROUP BY (sample_epoch DIV ${D_DIVIDER});"    \
  | sed 's/\t/;/g;s/\n//g' > "${DATASTORE}/sql13d.csv"
  ./insertdiff.py "${DATASTORE}/sql13d.csv"

  # Get day data for system memory usage (sysmem; graph14)
	echo -n "14"
  time mysql -h sql --skip-column-names -e             \
  "USE domotica;                                  \
   SELECT MIN(sample_epoch),                      \
          AVG(used),                              \
          AVG(buffers),                           \
          AVG(cached),                            \
          AVG(free),                              \
          AVG(swapused)                           \
    FROM sysmem                                   \
    WHERE (sample_time >= NOW() - ${D_INTERVAL})  \
      AND (sample_time <= NOW() - ${DH_INTERVAL}) \
      AND (host = '${HOST}')                      \
    GROUP BY (sample_epoch DIV ${D_DIVIDER});"    \
  | sed 's/\t/;/g;s/\n//g' > "${DATASTORE}/sql14d.csv"

  # Get day data for system log (syslog; graph15)
	echo -n "15"
  time mysql -h sql --skip-column-names -e             \
  "USE domotica;                                  \
   SELECT MIN(sample_epoch),                      \
          MAX(p0),                                \
          MAX(p1),                                \
          MAX(p2),                                \
          MAX(p3),                                \
          MAX(p4),                                \
          MAX(p5),                                \
          MAX(p6),                                \
          MAX(p7)                                 \
    FROM syslog                                   \
    WHERE (sample_time >= NOW() - ${D_INTERVAL})  \
      AND (sample_time <= NOW() - ${DH_INTERVAL}) \
      AND (host = '${HOST}')                      \
    GROUP BY (sample_epoch DIV ${D_DIVIDER});"    \
  | sed 's/\t/;/g;s/\n//g' > "${DATASTORE}/sql15d.csv"

  if [ "${HOST}" == "boson" ]; then
    # Get day data for HDD temperatures (disktemp; graph19)
    echo -n "19"
    time mysql -h sql --skip-column-names -e            \
    "USE domotica;                                    \
      SELECT                                          \
        MIN(d1.sample_epoch),                         \
        AVG(d1.diskt) AS sdd,                         \
        AVG(d2.diskt) AS hda,                         \
        AVG(d3.diskt) AS hdb,                         \
        AVG(d4.diskt) AS hdc,                         \
        AVG(d5.diskt) AS hdd                          \
      FROM                                            \
        disktemp d1,                                  \
        disktemp d2,                                  \
        disktemp d3,                                  \
        disktemp d4,                                  \
        disktemp d5                                   \
      WHERE                                           \
        (d1.sample_time >= NOW() - ${D_INTERVAL})     \
        AND (d1.sample_time <= NOW() - ${DH_INTERVAL}) \
        AND (d1.host = '${HOST}')                     \
      	AND d1.sample_epoch = d2.sample_epoch         \
      	AND d1.sample_epoch = d3.sample_epoch         \
      	AND d1.sample_epoch = d4.sample_epoch         \
      	AND d1.sample_epoch = d5.sample_epoch         \
      	AND (d1.diskid LIKE '%d6dd5'                  \
      		AND d2.diskid LIKE '%20fce'                 \
      		AND d3.diskid LIKE '%043e2'                 \
      		AND d4.diskid LIKE '%a237b'                 \
      		AND d5.diskid LIKE '%7b79c'                 \
      		)                                           \
      GROUP BY (d1.sample_epoch DIV (${D_DIVIDER}))   \
      ;"                                              \
    | sed 's/\t/;/g;s/\n//g' > "${DATASTORE}/sql19d.csv"
  fi
popd >/dev/null
