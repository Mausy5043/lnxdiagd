#!/bin/bash

# Pull data from MySQL server and graph them.

LOCAL=$(date)
LOCALSECONDS=$(date -d "$LOCAL" +%s)
UTC=$(date -u -d "$LOCAL" +"%Y-%m-%d %H:%M:%S")  #remove timezone reference
UTCSECONDS=$(date -d "$UTC" +%s)
UTCOFFSET=$(($LOCALSECONDS-$UTCSECONDS))

pushd $HOME/lnxdiagd >/dev/null
  if [ $(cat /tmp/sql11.csv |wc -l) -gt 30 ]; then
    gnuplot -e "utc_offset='${UTCOFFSET}'" ./graph11.gp
  fi
  if [ $(cat /tmp/sql12.csv |wc -l) -gt 30 ]; then
    gnuplot -e "utc_offset='${UTCOFFSET}'" ./graph12.gp
  fi
  if [ $(cat /tmp/sql13.csv |wc -l) -gt 30 ]; then
    gnuplot -e "utc_offset='${UTCOFFSET}'" ./graph13.gp
  fi
  if [ $(cat /tmp/sql14.csv |wc -l) -gt 30 ]; then
    gnuplot -e "utc_offset='${UTCOFFSET}'" ./graph14.gp
  fi
  if [ $(cat /tmp/sql15.csv |wc -l) -gt 30 ]; then
    gnuplot -e "utc_offset='${UTCOFFSET}'" ./graph15.gp
  fi

popd >/dev/null
