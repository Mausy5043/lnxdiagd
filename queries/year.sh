#!/bin/bash

# Pull YEARLY data from MySQL server.

pushd "$HOME/lnxdiagd/queries/" >/dev/null  || exit 1

  # shellcheck disable=SC1091
  source ./sql-includes || exit

  #sleep $(echo $RANDOM/555 |bc)

  # Get year data for system temperature (systemp; graph11)
  mysql -h sql --skip-column-names -e             \
  "USE domotica;                                  \
   SELECT MIN(sample_epoch),                       \
          MIN(temperature),                       \
          AVG(temperature),                       \
          MAX(temperature)                        \
    FROM systemp                                  \
    WHERE (sample_time >= NOW() - ${Y_INTERVAL})  \
      AND (sample_time <= NOW() - ${W_INTERVAL})  \
      AND (host = '${HOST}')                      \
    GROUP BY YEAR(sample_time),                   \
             MONTH(sample_time),                  \
             WEEK(sample_time);"                  \
  | sed 's/\t/;/g;s/\n//g' > "${DATASTORE}/sql11y.csv"

  # Get year data for system load (sysload; graph12)
  mysql -h sql --skip-column-names -e             \
  "USE domotica;                                  \
   SELECT MIN(sample_epoch),                       \
          AVG(load5min),                          \
          AVG(user),                              \
          AVG(system),                            \
          AVG(waiting)                            \
    FROM sysload                                  \
    WHERE (sample_time >= NOW() - ${Y_INTERVAL})  \
      AND (sample_time <= NOW() - ${W_INTERVAL})  \
      AND (host = '${HOST}')                      \
    GROUP BY YEAR(sample_time),                   \
             MONTH(sample_time),                  \
             WEEK(sample_time);"                  \
  | sed 's/\t/;/g;s/\n//g' > "${DATASTORE}/sql12y.csv"

  # Get year data for system network load (sysnet; graph13)
  mysql -h sql --skip-column-names -e             \
  "USE domotica;                                  \
   SELECT MIN(sample_epoch),                       \
          AVG(etIn),                              \
          AVG(etOut  )                            \
    FROM sysnet                                   \
    WHERE (sample_time >= NOW() - ${Y_INTERVAL})  \
      AND (sample_time <= NOW() - ${W_INTERVAL})  \
      AND (host = '${HOST}')                      \
    GROUP BY YEAR(sample_time),                   \
             MONTH(sample_time),                  \
             WEEK(sample_time);"                  \
  | sed 's/\t/;/g;s/\n//g' > "${DATASTORE}/sql13y.csv"
popd >/dev/null
