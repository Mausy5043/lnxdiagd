#!/bin/bash

# Pull DAILY data from MySQL server.

AGE=0
if [[ $# -ne 0 ]]; then
  AGE=$1
fi

pushd "$HOME/lnxdiagd/queries/" >/dev/null || exit 1

  # shellcheck disable=SC1091
  source ./sql-includes || exit
  echo "Query Daily Data"

  if [[ $(find "${DATASTORE}/sql11d.csv" -mmin +$AGE) ]]; then
    # Get day data for system temperature (systemp; graph11)
  	echo -n "11"
    time mysql -h sql --skip-column-names -e        \
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
  fi

  # Get day data for system load (sysload; graph12)
  if [[ $(find "${DATASTORE}/sql12d.csv" -mmin +$AGE) ]]; then
    echo -n "12"
    time mysql -h sql --skip-column-names -e             \
    "USE domotica;                                  \
     SELECT MIN(sample_epoch),                      \
            MIN(load5min),                          \
            AVG(load5min),                          \
            MAX(load5min),                          \
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
  fi

  # Get day data for system network load (sysnet; graph13)
  if [[ $(find "${DATASTORE}/sql13d.csv" -mmin +$AGE) ]]; then
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
  fi

  # Get day data for system memory usage (sysmem; graph14)
  if [[ $(find "${DATASTORE}/sql14d.csv" -mmin +$AGE) ]]; then
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
  fi

  # Get day data for system log (syslog; graph15)
  if [[ $(find "${DATASTORE}/sql15d.csv" -mmin +$AGE) ]]; then
  	echo -n "15"
    time mysql -h sql --skip-column-names -e             \
    "USE domotica;                                  \
     SELECT MIN(sample_epoch),                      \
            SUM(p0),                               \
            SUM(p1),                               \
            SUM(p2),                               \
            SUM(p3),                               \
            SUM(p4),                               \
            SUM(p5),                               \
            SUM(p6),                               \
            SUM(p7)                                \
      FROM syslog                                   \
      WHERE (sample_time >= NOW() - ${D_INTERVAL})  \
        AND (sample_time <= NOW() - ${DH_INTERVAL}) \
        AND (host = '${HOST}')                      \
      GROUP BY (sample_epoch DIV ${D_DIVIDER});"    \
    | sed 's/\t/;/g;s/\n//g' > "${DATASTORE}/sql15d.csv"
  fi

  if [ "${HOST}" == "boson" ]; then
    # Get day data for HDD temperatures (disktemp; graph19)
    if [[ $(find "${DATASTORE}/sql19d.csv" -mmin +$AGE) ]]; then
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
  fi
popd >/dev/null
