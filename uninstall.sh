#!/bin/bash

# this repo gets installed either manually by the user or automatically by
# a `*boot` repo.
# The hostname is in /etc/hostname prior to running `install.sh` here!

ME=$(whoami)
HOSTNAME=$(cat /etc/hostname)

echo -n "Started UNinstalling LNXDIAGD on "; date

pushd "$HOME/lnxdiagd"
 source ./includes.sh


  sudo rm /etc/cron.d/lnxdiagd

  echo "  Stopping all diagnostic daemons"
  for $d in $diaglist; do
    echo "Stopping "$d
    eval "./lnxdiag"$d"d.py stop"
  done
  echo "  Stopping all service daemons"
  for $d in $srvclist; do
    echo "Stopping "$d
    eval "./lnxsvc"$d"d.py stop"
  done
popd

echo -n "Finished UNinstallation of LNXDIAGD on "; date
