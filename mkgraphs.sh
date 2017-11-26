#!/bin/bash

# Pull data from MySQL server and graph them.

AGE=0
if [[ $# -ne 0 ]]; then
  AGE=$1
fi

LOCAL=$(date)
LOCALSECONDS=$(date -d "$LOCAL" +%s)
UTC=$(date -u -d "$LOCAL" +"%Y-%m-%d %H:%M:%S")  #remove timezone reference
UTCSECONDS=$(date -d "$UTC" +%s)
UTCOFFSET=$((LOCALSECONDS - UTCSECONDS))
host=$(hostname)

pushd "$HOME/lnxdiagd" >/dev/null  || exit 1
  if [[ $(find "/tmp//lnxdiagd/site/img/day12.png" -mmin +$AGE) || ! -f "/tmp//lnxdiagd/site/img/day12.png" ]]; then
    if [ "$(wc -l < /tmp/lnxdiagd/mysql4gnuplot/sql11d.csv)" -gt 5 ]; then
  		echo -n "Graph 11"
      time gnuplot -e "utc_offset='${UTCOFFSET}'" ./graphs/graph11.gp
    fi
    if [ "$(wc -l < /tmp/lnxdiagd/mysql4gnuplot/sql12d.csv)" -gt 5 ]; then
  		echo -n "Graph 12"
      time gnuplot -e "utc_offset='${UTCOFFSET}'" ./graphs/graph12.gp
    fi
    if [ "$(wc -l < /tmp/lnxdiagd/mysql4gnuplot/sql13d.csv)" -gt 5 ]; then
  		echo -n "Graph 13"
      time gnuplot -e "utc_offset='${UTCOFFSET}'" ./graphs/graph13.gp
    fi
    if [ "$(wc -l < /tmp/lnxdiagd/mysql4gnuplot/sql14d.csv)" -gt 5 ]; then
  		echo -n "Graph 14"
      time gnuplot -e "utc_offset='${UTCOFFSET}'" ./graphs/graph14.gp
    fi
    if [ "$(wc -l < /tmp/lnxdiagd/mysql4gnuplot/sql15d.csv)" -gt 5 ]; then
  		echo -n "Graph 15"
      time gnuplot -e "utc_offset='${UTCOFFSET}'" ./graphs/graph15.gp
    fi

    if [ "${host}" == "boson" ]; then
      if [ "$(wc -l < /tmp/lnxdiagd/mysql4gnuplot/sql19d.csv)" -gt 5 ]; then
  		  echo -n "Graph 19"
        time gnuplot -e "utc_offset='${UTCOFFSET}'" ./graphs/graph19.gp
  		fi
    fi
  fi
popd >/dev/null
