#!/bin/bash

# restart.sh is run periodically by a cronjob.
# It checks the state of and (re-)starts daemons if they are not (yet) running.

HOSTNAME=$(hostname)
BRANCH=$(cat "$HOME/.lnxdiagd.branch")

# make sure working tree exists
if [ ! -d /tmp/lnxdiagd/site/img ]; then
  mkdir -p /tmp/lnxdiagd/site/img
  chmod -R 755 /tmp/lnxdiagd
fi
# make sure working tree exists
if [ ! -d /tmp/lnxdiagd/mysql ]; then
  mkdir -p /tmp/lnxdiagd/mysql
  chmod -R 755 /tmp/lnxdiagd
fi

pushd "$HOME/lnxdiagd" || exit 1
  # shellcheck disable=SC1091
  source ./includes

  # Check if DIAG daemons are running
  for daemon in $diaglist; do
    if [ -e "/tmp/lnxdiagd/$daemon.pid" ]; then
      if ! kill -0 $(cat "/tmp/lnxdiagd/$daemon.pid")  > /dev/null 2>&1; then
        logger -p user.err -t lnxdiagd-restarter "  * Stale daemon $daemon pid-file found."
        rm "/tmp/lnxdiagd/$daemon.pid"
          echo "  * Start DIAG $daemon"
        eval "./daemons/lnxdiag$daemon"d.py restart
      fi
    else
      logger -p user.notice -t lnxdiagd-restarter "Found daemon $daemon not running."
        echo "  * Start DIAG $daemon"
      eval "./daemons/lnxdiag$daemon"d.py restart
    fi
  done

  # Check if SVC daemons are running
  for daemon in $srvclist; do
    if [ -e "/tmp/lnxdiagd/$daemon.pid" ]; then
      if ! kill -0 $(cat "/tmp/lnxdiagd/$daemon.pid")  > /dev/null 2>&1; then
        logger -p user.err -t lnxdiagd-restarter "* Stale daemon $daemon pid-file found."
        rm "/tmp/lnxdiagd/$daemon.pid"
          echo "  * Start SVC $daemon"
        eval "./daemons/lnxsvc$daemon"d.py restart
      fi
    else
      logger -p user.notice -t lnxdiagd-restarter "Found daemon $daemon not running."
        echo "  * Start SVC $daemon"
      eval "./daemons/lnxsvc$daemon"d.py restart
    fi
  done

  # Do some host specific stuff
  case "$HOSTNAME" in
    rbagain ) echo "Weather Monitor"
              ;;
    bbone )   echo "BeagleBone Black"
              ;;
    rbups )   echo "UPS monitor"
              ;;
    rbux  )   echo "Testbench"
              ;;
    rbux3 )   echo "Testbench RPi3"
              ;;
    rbelec )  echo "Electricity monitor"
              ;;
    rbian )   echo "Raspberry testbench"
              ;;
    osmc )    echo "OSMC Media Center"
              ;;
    boson )   echo "BOSON"
              if [ -e /tmp/lnxdiagd/19.pid ]; then
                if ! kill -0 $(cat /tmp/lnxdiagd/19.pid)  > /dev/null 2>&1; then
                  logger -p user.err -t lnxdiagd-restarter "* Stale daemon 19 pid-file found."
                  rm /tmp/lnxdiagd/19.pid
                  echo "  * Start DIAG 19"
                  eval ./daemons/lnxdiag19d.py restart
                fi
              else
                logger -p user.notice -t lnxdiagd-restarter "Found daemon 19 not running."
                echo "  * Start DIAG 19"
                eval ./daemons/lnxdiag19d.py restart
              fi
              ;;
    neutron ) echo "NEUTRON"
              ;;
    * )       echo "!! undefined client !!"
              ;;
  esac
popd
