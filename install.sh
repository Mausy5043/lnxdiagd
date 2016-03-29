#!/bin/bash

# this repo gets installed either manually by the user or automatically by
# a `*boot` repo.
# The hostname is in /etc/hostname prior to running `install.sh` here!

ME=$(whoami)
HOSTNAME=$(cat /etc/hostname)

echo -n "Started installing LNXDIAGD on "; date

pushd "$HOME/lnxdiagd"
  # To suppress git detecting changes by chmod:
  git config core.fileMode false
  # set the branch
  if [ ! -e "$HOME/.lnxdiagd.branch" ]; then
    echo "master" > "$HOME/.lnxdiagd.branch"
  fi

  # Create the /etc/cron.d directory if it doesn't exist
  sudo mkdir -p /etc/cron.d

  # Set up some cronjobs
  echo "# m h dom mon dow user  command" | sudo tee /etc/cron.d/lnxdiagd
  echo "42  * *   *   *   $ME    $HOME/lnxdiagd/update.sh 2>&1 | logger -p info -t lnxdiagd" | sudo tee --append /etc/cron.d/lnxdiagd
  # @reboot we allow for 120s for the WiFi to come up:
  echo "@reboot           $ME    sleep 120; $HOME/lnxdiagd/update.sh 2>&1 | logger -p info -t lnxdiagd" | sudo tee --append /etc/cron.d/lnxdiagd

  #./update.sh
popd

# make sure all mountpoints exist
sudo mkdir -p /mnt/share1
sudo mkdir -p /mnt/backup

echo -n "Finished installation of LNXDIAGD on "; date
