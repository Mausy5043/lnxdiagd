#!/bin/bash

# update.sh is run periodically by a cronjob.
# * It synchronises the local copy of LNXDIAGD with the current github branch
# * It checks the state of and (re-)starts daemons if they are not (yet) running.

HOSTNAME=$(cat /etc/hostname)
branch=$(cat "$HOME/.lnxdiagd.branch")

# make sure working directory exists
if [[ ! -d /tmp/lnxdiagd ]]; then
  mkdir -p /tmp/lnxdiagd
fi
pushd "$HOME/lnxdiagd"
 source ./includes.sh
  git fetch origin
  # Check which files have changed
  DIFFLIST=$(git --no-pager diff --name-only "$branch..origin/$branch")
  git pull
  git fetch origin
  git checkout "$branch"
  git reset --hard "origin/$branch" && git clean -f -d
  # Set permissions
  chmod -R 744 ./*

  for fname in $DIFFLIST; do
    echo " $fname was updated from GIT"
    f7l4="${fname:0:7}${fname:${#fname}-4}"
    f6l4="${fname:0:6}${fname:${#fname}-4}"
    if [[ "$f7l4" == "lnxdiagd.py" ]]; then
      echo "- Diagnostic daemon changed"
      eval "./"$fname" restart"
    fi
    if [[ "$f6l4" == "lnxsvc.py" ]]; then
      echo "- Diagnostic service daemon changed"
      eval "./"$fname" restart"
    fi
    if [[ "$fname" == "libdaemon.py" ]]; then
      echo "- Diagnostic library changed"
      echo "  Restarting all diagnostic daemons"
      for daemon in $diaglist; do
        echo "Restart DIAG "$daemon
        eval "./lnxdiag"$daemon"d.py restart"
      done
      echo "  Restarting all service daemons"
      for daemon in $srvclist; do
        echo "Restart SVC "$daemon
        eval "./lnxsvc"$daemon"d.py restart"
      done
    fi
  done
  for daemon in $diaglist; do
    if [ -e "/tmp/lnxdiagd/$daemon.pid" ]; then
      if ! kill -0 $(cat "/tmp/lnxdiagd/$daemon.pid")  > /dev/null 2>&1; then
        logger -p user.err -t lnxdiagd "* Stale daemon $daemon pid-file found."
        rm "/tmp/lnxdiagd/$daemon.pid"
          echo "Start DIAG "$daemon
        eval "./lnxdiag"$daemon"d.py start"
      fi
    else
      logger -p user.warn -t raspdiagd "Found daemon $daemon not running."
        echo "Start DIAG "$daemon
      eval "./lnxdiag"$daemon"d.py start"
    fi
  done
  for daemon in $srvclist; do
    if [ -e "/tmp/lnxdiagd/$daemon.pid" ]; then
      if ! kill -0 $(cat "/tmp/lnxdiagd/$daemon.pid")  > /dev/null 2>&1; then
        logger -p user.err -t lnxdiagd "* Stale daemon $daemon pid-file found."
        rm "/tmp/lnxdiagd/$daemon.pid"
          echo "Start SVC "$daemon
        eval "./lnxsvc"$daemon"d.py start"
      fi
    else
      logger -p user.warn -t raspdiagd "Found daemon $daemon not running."
        echo "Start SVC "$daemon
      eval "./lnxsvc"$daemon"d.py start"
    fi
  done

  case "$HOSTNAME" in
    bbone )   echo "BeagleBone Black"
              ;;
    rbups )   echo "UPS monitor"
              ;;
    rbelec )  echo "Electricity monitor"
              ;;
    rbian )   echo "Raspberry testbench"
              ;;
    osmc )    echo "OSMC Media Center"
              ;;
    boson )   echo "BOSON"
              ;;
    neutron ) echo "NEUTRON"
              ;;
    * )       echo "!! undefined client !!"
              ;;
  esac
popd

# the $MOUNTPOINT is in /etc/fstab
# in the unlikely event that the mount was lost,
# remount it here.
MOUNTPOINT=/mnt/share1
MOUNTDRIVE=boson.lan:/srv/array1/dataspool
if grep -qs $MOUNTPOINT /proc/mounts; then
    # It's mounted.
  echo "mounted"
else
    # Mount the share containing the data
    mount $MOUNTDRIVE $MOUNTPOINT
fi
