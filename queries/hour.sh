#!/bin/bash

# Pull data from MySQL server.

pushd "$HOME/lnxdiagd/queries/" >/dev/null || exit 1

  # shellcheck disable=SC1091
  source ./sql-includes || exit
  echo "Query Hourly Data"


  # Get hour data for system temperature (systemp; graph11)
	echo -n "11"
  time mysql -h sql --skip-column-names -e            \
  "USE domotica;                                 \
   SELECT MIN(sample_epoch),                     \
          AVG(temperature)                       \
    FROM systemp                                 \
    WHERE (sample_time >= NOW() - ${H_INTERVAL}) \
      AND (host = '${HOST}')                     \
    GROUP BY (sample_epoch DIV ${H_DIVIDER});"   \
  | sed 's/\t/;/g;s/\n//g' > "${DATASTORE}/sql11h.csv"

  # Get hour data for system load (sysload; graph12)
  # multiply H_DIVIDER by 5 because sampling takes place every 300s (5*60s)
	echo -n "12"
  time mysql -h sql --skip-column-names -e            \
  "USE domotica;                                 \
   SELECT MIN(sample_epoch),                     \
          AVG(load5min),                         \
          AVG(user),                             \
          AVG(system),                           \
          AVG(waiting),                          \
          AVG(idle)                              \
    FROM sysload                                 \
    WHERE (sample_time >= NOW() - ${H_INTERVAL}) \
      AND (host = '${HOST}')                     \
    GROUP BY (sample_epoch DIV (${H_DIVIDER}*5));"   \
  | sed 's/\t/;/g;s/\n//g' > "${DATASTORE}/sql12h.csv"

  # Get hour data for system network load (sysnet; graph13)
	echo -n "13"
  time mysql -h sql --skip-column-names -e            \
  "USE domotica;                                  \
   SELECT MIN(sample_epoch),                      \
          MIN(etIn),                              \
          MAX(etIn),                              \
          MIN(etOut),                             \
          MAX(etOut)                              \
    FROM sysnet                                   \
    WHERE (sample_time >= NOW() - ${H_INTERVAL})  \
      AND (host = '${HOST}')                      \
    GROUP BY (sample_epoch DIV (${H_DIVIDER}));"  \
  | sed 's/\t/;/g;s/\n//g' > "${DATASTORE}/sql13h.csv"
  cp "${DATASTORE}/sql13h.csv" "${DATASTORE}/sql13h.bak"
  ./insertdiff.py "${DATASTORE}/sql13h.csv"

  # Get hour data for system memory usage (sysmem; graph14)
	echo -n "14"
  time mysql -h sql --skip-column-names -e            \
  "USE domotica;                                 \
   SELECT MIN(sample_epoch),                     \
          AVG(used),                             \
          AVG(buffers),                          \
          AVG(cached),                           \
          AVG(free),                             \
          AVG(swapused)                          \
    FROM sysmem                                  \
    WHERE (sample_time >= NOW() - ${H_INTERVAL}) \
      AND (host = '${HOST}')                     \
    GROUP BY (sample_epoch DIV ${H_DIVIDER});"   \
  | sed 's/\t/;/g;s/\n//g' > "${DATASTORE}/sql14h.csv"

  # Get hour data for system log (syslog; graph15)
  # (multiply H_DIVIDER by 10 because sampling takes place every 600s)
  	echo -n "15"
  time mysql -h sql --skip-column-names -e            \
  "USE domotica;                                 \
   SELECT MIN(sample_epoch),                     \
          SUM(p0),                               \
          SUM(p1),                               \
          SUM(p2),                               \
          SUM(p3),                               \
          SUM(p4),                               \
          SUM(p5),                               \
          SUM(p6),                               \
          SUM(p7)                                \
    FROM syslog                                  \
    WHERE (sample_time >= NOW() - ${H_INTERVAL}) \
      AND (host = '${HOST}')                     \
    GROUP BY (sample_epoch DIV (${H_DIVIDER}*10));"   \
  | sed 's/\t/;/g;s/\n//g' > "${DATASTORE}/sql15h.csv"

  if [ "${HOST}" == "boson" ]; then
    # Get hour data for HDD temperatures (disktemp; graph19)
    # multiply H_DIVIDER by 5 because sampling takes place every 300s (5*60s)
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
        (d1.sample_time >= NOW() - ${H_INTERVAL})     \
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
      GROUP BY (d1.sample_epoch DIV (${H_DIVIDER}*5)) \
      ;"                                              \
    | sed 's/\t/;/g;s/\n//g' > "${DATASTORE}/sql19h.csv"
  fi
popd >/dev/null
