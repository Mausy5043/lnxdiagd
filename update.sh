#!/bin/bash

# update.sh is run manually
# * It synchronises the local copy of LNXDIAGD with the current github BRANCH
# * It checks the state of and (re-)starts daemons if they are not (yet) running.

HOSTNAME=$(hostname)
BRANCH=$(cat "$HOME/.lnxdiagd.branch")

# Wait for the daemons to finish their job. Prevents stale locks when restarting.
#echo "Waiting 30s..."
#sleep 30

# make sure working tree exists
if [ ! -d /tmp/lnxdiagd/site/img ]; then
  mkdir -p /tmp/lnxdiagd/site/img
  chmod -R 755 /tmp/lnxdiagd
fi
# make sure working tree exists
if [ ! -d /tmp/lnxdiagd/mysql4gnuplot ]; then
  mkdir -p /tmp/lnxdiagd/mysql4gnuplot
  chmod -R 755 /tmp/lnxdiagd
fi

pushd "$HOME/lnxdiagd"
  # shellcheck disable=SC1091
  source ./includes
  git fetch origin
  # Check which files have changed
  DIFFLIST=$(git --no-pager diff --name-only "$BRANCH..origin/$BRANCH")
  git pull
  git fetch origin
  git checkout "$BRANCH"
  git reset --hard "origin/$BRANCH" && git clean -f -d
  # Set permissions
  # chmod -R 744 ./*

  for fname in $DIFFLIST; do
    echo ">   $fname was updated from GIT"
    f7l4="${fname:0:15}${fname:${#fname}-4}"
    f6l4="${fname:0:14}${fname:${#fname}-4}"
    f5l3="${fname:0:14}${fname:${#fname}-4}"

    # Detect DIAG changes
    if [[ "$f7l4" == "daemons/lnxdiagd.py" ]]; then
      echo "  ! Diagnostic daemon changed"
      eval "./$fname stop"
    fi

    # Detect SVC changes
    if [[ "$f6l4" == "daemons/lnxsvcd.py" ]]; then
      echo "  ! Service daemon changed"
      eval "./$fname stop"
    fi

    #CONFIG.INI changed
    if [[ "$fname" == "config.ini" ]]; then
      echo "  ! Configuration file changed"
      echo "  o Restarting all daemons"
      for daemon in $diaglist; do
        echo "  +- Restart DIAG ${daemon}"
        eval "./daemons/lnxdiag${daemon}d.py restart"
      done
      echo "  o Restarting all service daemons"
      for daemon in $srvclist; do
        echo "  +- Restart SVC ${daemon}"
        eval "./daemons/lnxsvc${daemon}d.py restart"
      done
    fi
  done

  # Check if DIAG daemons are running
  for daemon in $diaglist; do
    if [ -e "/tmp/lnxdiagd/${daemon}.pid" ]; then
      if ! kill -0 $(cat "/tmp/lnxdiagd/${daemon}.pid")  > /dev/null 2>&1; then
        logger -p user.err -t lnxdiagd "  * Stale daemon ${daemon} pid-file found."
        rm "/tmp/lnxdiagd/${daemon}.pid"
          echo "  * Start DIAG ${daemon}"
        eval "./daemons/lnxdiag${daemon}d.py start"
      fi
    else
      logger -p user.notice -t lnxdiagd "Found daemon ${daemon} not running."
        echo "  * Start DIAG ${daemon}"
      eval "./daemons/lnxdiag${daemon}d.py start"
    fi
  done

  # Check if SVC daemons are running
  for daemon in $srvclist; do
    if [ -e "/tmp/lnxdiagd/${daemon}.pid" ]; then
      if ! kill -0 $(cat "/tmp/lnxdiagd/${daemon}.pid")  > /dev/null 2>&1; then
        logger -p user.err -t lnxdiagd "* Stale daemon ${daemon} pid-file found."
        rm "/tmp/lnxdiagd/${daemon}.pid"
          echo "  * Start SVC ${daemon}"
        eval "./daemons/lnxsvc${daemon}d.py start"
      fi
    else
      logger -p user.notice -t lnxdiagd "Found daemon ${daemon} not running."
        echo "  * Start SVC ${daemon}"
      eval "./daemons/lnxsvc${daemon}d.py start"
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
                  eval ./daemons/lnxdiag19d.py restart
                fi
              else
                logger -p user.notice -t lnxdiagd "Found daemon 19 not running."
                echo "  * Start DIAG 19"
                eval ./daemons/lnxdiag19d.py start
              fi
              ;;
    neutron ) echo "NEUTRON"
              ;;
    * )       echo "!! undefined client !!"
              ;;
  esac
popd
