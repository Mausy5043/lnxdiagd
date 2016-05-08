#!/bin/bash

# this repo gets installed either manually by the user or automatically by
# a `*boot` repo.

ME=$(whoami)

echo -n "Started installing LNXDIAGD on "; date

# See if packages are installed and install them.
python=$(dpkg-query -W -f='${Status} ${Version}\n' python 2>/dev/null | wc -l)
git=$(dpkg-query -W -f='${Status} ${Version}\n' git 2>/dev/null | wc -l)
lftp=$(dpkg-query -W -f='${Status} ${Version}\n' lftp 2>/dev/null | wc -l)
if [ $python -eq 0 ]; then
  sudo apt-get -yuV install python
fi
if [ $git -eq 0 ]; then
  sudo apt-get -yuV install git
fi
if [ $lftp -eq 0 ]; then
  sudo apt-get -yuV install lftp
fi

minit=$(echo $RANDOM/555 |bc)
echo "MINIT = "$minit


pushd "$HOME/lnxdiagd"
  # To suppress git detecting changes by chmod:
  git config core.fileMode false
  # set the branch
  if [ ! -e "$HOME/.lnxdiagd.branch" ]; then
    echo "v2_0" > "$HOME/.lnxdiagd.branch"
  fi

  # Create the /etc/cron.d directory if it doesn't exist
  sudo mkdir -p /etc/cron.d

  # Set up some cronjobs
  echo "# m h dom mon dow user  command" | sudo tee /etc/cron.d/lnxdiagd
  echo "$minit  * *   *   *   $ME    $HOME/lnxdiagd/update.sh 2>&1 | logger -p info -t lnxdiagd" | sudo tee --append /etc/cron.d/lnxdiagd
  # @reboot we allow for 120s for the WiFi to come up:
  echo "@reboot               $ME    sleep 120; $HOME/lnxdiagd/update.sh 2>&1 | logger -p info -t lnxdiagd" | sudo tee --append /etc/cron.d/lnxdiagd

  #./update.sh
popd

echo -n "Finished installation of LNXDIAGD on "; date
