#!/bin/bash

# Pull WEEKLY data from MySQL server and graph them.

pushd "$HOME/lnxdiagd/queries/" >/dev/null || exit 1

  # shellcheck disable=SC1091
  source ./sql-includes || exit

  #sleep $(echo $RANDOM/555 |bc)

  #mysql -h sql --skip-column-names -e "USE domotica; SELECT * FROM systemp where (sample_time >=NOW() - ${W_INTERVAL}) AND (sample_time <= NOW() - ${WD_INTERVAL}) AND (host = '${HOST}');" | sed 's/\t/;/g;s/\n//g' > "${DATASTORE}/sql11w.csv"
  #mysql -h sql --skip-column-names -e "USE domotica; SELECT * FROM sysload where (sample_time >=NOW() - ${W_INTERVAL}) AND (sample_time <= NOW() - ${WD_INTERVAL}) AND (host = '${HOST}');" | sed 's/\t/;/g;s/\n//g' > "${DATASTORE}/sql12w.csv"
  #mysql -h sql --skip-column-names -e "USE domotica; SELECT * FROM sysnet  where (sample_time >=NOW() - ${W_INTERVAL}) AND (sample_time <= NOW() - ${WD_INTERVAL}) AND (host = '${HOST}');" | sed 's/\t/;/g;s/\n//g' > "${DATASTORE}/sql13w.csv"
  #mysql -h sql --skip-column-names -e "USE domotica; SELECT * FROM sysmem  where (sample_time >=NOW() - ${W_INTERVAL}) AND (sample_time <= NOW() - ${WD_INTERVAL}) AND (host = '${HOST}');" | sed 's/\t/;/g;s/\n//g' > "${DATASTORE}/sql14w.csv"
  #mysql -h sql --skip-column-names -e "USE domotica; SELECT * FROM syslog  where (sample_time >=NOW() - ${W_INTERVAL}) AND (sample_time <= NOW() - ${WD_INTERVAL}) AND (host = '${HOST}');" | sed 's/\t/;/g;s/\n//g' > "${DATASTORE}/sql15w.csv"

  #http://www.sitepoint.com/understanding-sql-joins-mysql-database/
  #mysql -h sql --skip-column-names -e "USE domotica; SELECT ds18.sample_time, ds18.sample_epoch, ds18.temperature, wind.speed FROM ds18 INNER JOIN wind ON ds18.sample_epoch = wind.sample_epoch WHERE (ds18.sample_time) >=NOW() - W_INTERVAL 1 MINUTE;" | sed 's/\t/;/g;s/\n//g' > ${DATASTORE}/sql2c.csv
  if [ "${HOST}" == "boson" ]; then
    mysql -h sql --skip-column-names < data19w.sql | sed 's/\t/;/g;s/\n//g' > "${DATASTORE}/sql19w.csv"
  fi

  # Get week data for system temperature (systemp; graph11)
	echo -n "11"
  time mysql -h sql --skip-column-names -e             \
  "USE domotica;                                  \
   SELECT MIN(sample_epoch),                      \
          MIN(temperature),                       \
          AVG(temperature),                       \
          MAX(temperature)                        \
    FROM systemp                                  \
    WHERE (sample_time >= NOW() - ${W_INTERVAL})  \
      AND (sample_time <= NOW() - ${WD_INTERVAL}) \
      AND (host = '${HOST}')                      \
    GROUP BY (sample_epoch DIV ${W_DIVIDER});"    \
  | sed 's/\t/;/g;s/\n//g' > "${DATASTORE}/sql11w.csv"

  # Get week data for system load (sysload; graph12)
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
    WHERE (sample_time >= NOW() - ${W_INTERVAL})  \
      AND (sample_time <= NOW() - ${WD_INTERVAL}) \
      AND (host = '${HOST}')                      \
    GROUP BY (sample_epoch DIV ${W_DIVIDER});"    \
  | sed 's/\t/;/g;s/\n//g' > "${DATASTORE}/sql12w.csv"

  # Get week data for system network load (sysnet; graph13)
	echo -n "13"
  time mysql -h sql --skip-column-names -e             \
  "USE domotica;                                  \
   SELECT MIN(sample_epoch),                      \
          MIN(etIn),                              \
          MAX(etIn),                              \
          MIN(etOut),                             \
          MAX(etOut)                              \
    FROM sysnet                                   \
    WHERE (sample_time >= NOW() - ${W_INTERVAL})  \
      AND (sample_time <= NOW() - ${WD_INTERVAL}) \
      AND (host = '${HOST}')                      \
    GROUP BY (sample_epoch DIV ${W_DIVIDER});"    \
  | sed 's/\t/;/g;s/\n//g' > "${DATASTORE}/sql13w.csv"
  ./insertdiff.py "${DATASTORE}/sql13w.csv"

  # Get week data for system memory usage (sysmem; graph14)
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
    WHERE (sample_time >= NOW() - ${W_INTERVAL})  \
      AND (sample_time <= NOW() - ${WD_INTERVAL}) \
      AND (host = '${HOST}')                      \
    GROUP BY (sample_epoch DIV ${W_DIVIDER});"    \
  | sed 's/\t/;/g;s/\n//g' > "${DATASTORE}/sql14w.csv"

  # Get week data for system log (syslog; graph15)
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
    WHERE (sample_time >= NOW() - ${W_INTERVAL})  \
      AND (sample_time <= NOW() - ${WD_INTERVAL}) \
      AND (host = '${HOST}')                      \
    GROUP BY (sample_epoch DIV ${W_DIVIDER});"    \
  | sed 's/\t/;/g;s/\n//g' > "${DATASTORE}/sql15w.csv"

popd >/dev/null
