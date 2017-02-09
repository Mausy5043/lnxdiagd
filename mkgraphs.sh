#!/bin/bash

# Pull data from MySQL server and graph them.

LOCAL=$(date)
LOCALSECONDS=$(date -d "$LOCAL" +%s)
UTC=$(date -u -d "$LOCAL" +"%Y-%m-%d %H:%M:%S")  #remove timezone reference
UTCSECONDS=$(date -d "$UTC" +%s)
UTCOFFSET=$((LOCALSECONDS - UTCSECONDS))
host=$(hostname)

pushd "$HOME/lnxdiagd" >/dev/null
  #if [ $(wc -l < /tmp/lnxdiagd/mysql/sql11d.csv) -gt 5 ]; then
  #  gnuplot -e "utc_offset='${UTCOFFSET}'" ./graph11.gp &
  #fi
  if [ $(wc -l < /tmp/lnxdiagd/mysql/sql12d.csv) -gt 5 ]; then
    time gnuplot -e "utc_offset='${UTCOFFSET}'" ./graph12.gp &
  fi
  wait
  if [ $(wc -l < /tmp/lnxdiagd/mysql/sql13d.csv) -gt 5 ]; then
    time gnuplot -e "utc_offset='${UTCOFFSET}'" ./graph13.gp &
  fi
  if [ $(wc -l < /tmp/lnxdiagd/mysql/sql14d.csv) -gt 5 ]; then
    time gnuplot -e "utc_offset='${UTCOFFSET}'" ./graph14.gp &
  fi
  wait
  if [ $(wc -l < /tmp/lnxdiagd/mysql/sql15d.csv) -gt 5 ]; then
    time gnuplot -e "utc_offset='${UTCOFFSET}'" ./graph15.gp &
  fi

  if [ "$host" == "boson" ]; then
    if [ $(wc -l < /tmp/lnxdiagd/mysql/sql19d.csv) -gt 5 ]; then
      time gnuplot -e "utc_offset='${UTCOFFSET}'" ./graph19.gp &
		fi
  fi
  wait

  time ./graph11.py

popd >/dev/null
