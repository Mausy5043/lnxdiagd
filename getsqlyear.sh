#!/bin/bash

# Pull YEARLY data from MySQL server.

######
datastore="/tmp/domog/mysql4python"

interval="INTERVAL 370 DAY "

if [ ! -d "${datastore}" ]; then
  mkdir -p "${datastore}"
fi

pushd "$HOME/lnxdiagd" >/dev/null
  # Get year data for system temperature (systemp; graph11)
  # DIV t : t/100 minutes
  # t=18000 3h
  mysql -h sql.lan --skip-column-names -e \
  "USE domotica; \
   SELECT MIN(sample_time), MIN(temperature), AVG(temperature), MAX(temperature) \
   FROM systemp \
   WHERE (sample_time >= NOW() - ${interval}) AND (host = '${host}') \
   GROUP BY YEAR(sample_time), MONTH(sample_time), DAY(sample_time);" \
  | sed 's/\t/;/g;s/\n//g' > "${datastore}/sql11y.csv"

popd >/dev/null
