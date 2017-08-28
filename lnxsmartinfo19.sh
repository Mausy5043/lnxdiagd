#! /bin/bash

# This script is executed periodically by a cronjob.
# It prevents the use of repeated `sudo smartctl...` commands
# The resulting data is stored in `/tmp/mausy5043libs/*.dat` files that are
# subsequently read by `daemons/lnxdiag19d.py`.

rf="/tmp/mausy5043libs/smartinfo"

# BEWARE
# The disks identified here as `sda`, `sdb` etc. may not necessarily
# be called `/dev/sda`, `/dev/sdb` etc. on the system!!
sda="wwn-0x50026b723c0d6dd5"  # SSD 50026B723C0D6DD5
sdb="wwn-0x50014ee261020fce"  # WD-WCC4N5PF96KD
sdc="wwn-0x50014ee605a043e2"  # WD-WMC4N0K01249
sdd="wwn-0x50014ee6055a237b"  # WD-WMC4N0J6Y6LW
sde="wwn-0x50014ee60507b79c"  # WD-WMC4N0E24DVU
sdf="wwn-0x50014ee262ed6df5"  # WD-WCC4J0JPYS0D
# sdgl=""

function smart1999 {
  if [[ -e "/dev/disk/by-id/${1}" ]]; then
    if [[ ! -e "${rf}-${1}-i.dat" ]]; then
      # this is static info, therefore only get it if it's not there.
      smartctl -i "/dev/disk/by-id/${1}" |awk 'NR>4' > "${rf}-${1}-i.dat"
    fi
    smartctl -A "/dev/disk/by-id/${1}" |awk 'NR>7' > "${rf}-${1}-A.dat"
    smartctl -H "/dev/disk/by-id/${1}" |grep 'test result' > "${rf}-${1}-H.dat"
    smartctl -l selftest "/dev/disk/by-id/${1}" |grep '\# 1' > "${rf}-${1}-l.dat"
    chmod 744 "${rf}-*"
  fi
}

if [[ ! -d /tmp/lnxdiagd ]]; then
  mkdir -m 777 /tmp/lnxdiagd
fi

touch "${rf}.lock"
smart1999 $sda
smart1999 $sdb
smart1999 $sdc
smart1999 $sdd
smart1999 $sde
smart1999 $sdf
rm "${rf}.lock"
