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

pushd "$HOME/lnxdiagd"
  source ./includes

  # Check if DIAG daemons are running
  for daemon in $diaglist; do
    if [ -e "/tmp/lnxdiagd/$daemon.pid" ]; then
      if ! kill -0 $(cat "/tmp/lnxdiagd/$daemon.pid")  > /dev/null 2>&1; then
        logger -p user.err -t lnxdiagd "  * Stale daemon $daemon pid-file found."
        rm "/tmp/lnxdiagd/$daemon.pid"
          echo "  * Start DIAG $daemon"
        eval "./lnxdiag$daemon"d.py start
      fi
    else
      logger -p user.notice -t lnxdiagd "Found daemon $daemon not running."
        echo "  * Start DIAG $daemon"
      eval "./lnxdiag$daemon"d.py start
    fi
  done

  # Check if SVC daemons are running
  for daemon in $srvclist; do
    if [ -e "/tmp/lnxdiagd/$daemon.pid" ]; then
      if ! kill -0 $(cat "/tmp/lnxdiagd/$daemon.pid")  > /dev/null 2>&1; then
        logger -p user.err -t lnxdiagd "* Stale daemon $daemon pid-file found."
        rm "/tmp/lnxdiagd/$daemon.pid"
          echo "  * Start SVC $daemon"
        eval "./lnxsvc$daemon"d.py start
      fi
    else
      logger -p user.notice -t lnxdiagd "Found daemon $daemon not running."
        echo "  * Start SVC $daemon"
      eval "./lnxsvc$daemon"d.py start
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
                  logger -p user.err -t lnxdiagd "* Stale daemon 19 pid-file found."
                  rm /tmp/lnxdiagd/19.pid
                  echo "  * Start DIAG 19"
                  eval ./lnxdiag19d.py restart
                fi
              else
                logger -p user.notice -t lnxdiagd "Found daemon 19 not running."
                echo "  * Start DIAG 19"
                eval ./lnxdiag19d.py start
              fi
              ;;
    neutron ) echo "NEUTRON"
              ;;
    * )       echo "!! undefined client !!"
              ;;
  esac
popd
