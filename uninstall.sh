#!/bin/bash

# this repo gets installed either manually by the user or automatically by
# a `*boot` repo.
# The hostname is in /etc/hostname prior to running `install.sh` here!

HOSTNAME=$(cat /etc/hostname)

echo -n "Started UNinstalling LNXDIAGD on "; date

pushd "$HOME/lnxdiagd"
 source ./includes


  sudo rm /etc/cron.d/lnxdiagd

  echo "  Stopping all diagnostic daemons"
  for daemon in $diaglist; do
    echo "Stopping "$daemon
    eval "./daemon/lnxdiag"$daemon"d.py stop"
  done
  echo "  Stopping all service daemons"
  for daemon in $srvclist; do
    echo "Stopping "$daemon
    eval "./lnxsvc"$daemon"d.py stop"
  done
popd

echo -n "Finished UNinstallation of LNXDIAGD on "; date
