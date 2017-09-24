#!/bin/bash

# Pull YEARLY data from MySQL server.

pushd "$HOME/lnxdiagd/queries/" >/dev/null || exit 1

  # shellcheck disable=SC1091
  source ./sql-includes || exit
  echo "Query Yearly Data"


  # Get year data for system temperature (systemp; graph11)
	echo -n "11"
  time mysql -h sql --skip-column-names -e             \
  "USE domotica;                                  \
   SELECT MIN(sample_epoch),                      \
          MIN(temperature),                       \
          AVG(temperature),                       \
          MAX(temperature)                        \
    FROM systemp                                  \
    WHERE (sample_time >= NOW() - ${Y_INTERVAL})  \
      AND (sample_time <= NOW() - ${W_INTERVAL})  \
      AND (host = '${HOST}')                      \
    GROUP BY YEAR(sample_time),                   \
             WEEK(sample_time, 3);"                  \
  | sed 's/\t/;/g;s/\n//g' | sort -t ";" -k 1 > "${DATASTORE}/sql11y.csv"

  # Get year data for system load (sysload; graph12)
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
    WHERE (sample_time >= NOW() - ${Y_INTERVAL})  \
      AND (sample_time <= NOW() - ${W_INTERVAL})  \
      AND (host = '${HOST}')                      \
    GROUP BY YEAR(sample_time),                   \
             WEEK(sample_time, 3);"                  \
  | sed 's/\t/;/g;s/\n//g' | sort -t ";" -k 1 > "${DATASTORE}/sql12y.csv"

  # Get year data for system network load (sysnet; graph13)
	echo -n "13"
  time mysql -h sql --skip-column-names -e             \
  "USE domotica;                                  \
   SELECT MIN(sample_epoch),                      \
          MIN(etIn),                              \
          MAX(etIn),                              \
          MIN(etOut),                             \
          MAX(etOut)                              \
    FROM sysnet                                   \
    WHERE (sample_time >= NOW() - ${Y_INTERVAL})  \
      AND (sample_time <= NOW() - ${W_INTERVAL})  \
      AND (host = '${HOST}')                      \
    GROUP BY YEAR(sample_time),                   \
             WEEK(sample_time, 3);"                  \
  | sed 's/\t/;/g;s/\n//g' | sort -t ";" -k 1 > "${DATASTORE}/sql13y.csv"
  ./insertdiff.py "${DATASTORE}/sql13y.csv"

  # Get year data for system memory usage (sysmem; graph14)
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
    WHERE (sample_time >= NOW() - ${Y_INTERVAL})  \
      AND (sample_time <= NOW() - ${W_INTERVAL})  \
      AND (host = '${HOST}')                      \
    GROUP BY YEAR(sample_time),                   \
             WEEK(sample_time, 3);"                  \
  | sed 's/\t/;/g;s/\n//g' | sort -t ";" -k 1 > "${DATASTORE}/sql14y.csv"

  # Get year data for system log (syslog; graph15)
	echo -n "15"
  time mysql -h sql --skip-column-names -e             \
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
    WHERE (sample_time >= NOW() - ${Y_INTERVAL}) \
      AND (sample_time <= NOW() - ${W_INTERVAL}) \
      AND (host = '${HOST}')                     \
    GROUP BY YEAR(sample_time),                  \
             WEEK(sample_time, 3);"              \
  | sed 's/\t/;/g;s/\n//g' | sort -t ";" -k 1 > "${DATASTORE}/sql15y.csv"
popd >/dev/null
