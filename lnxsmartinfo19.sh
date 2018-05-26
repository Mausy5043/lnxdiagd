#! /bin/bash

# This script is executed periodically by a cronjob.
# It prevents the use of repeated `sudo smartctl...` commands
# The resulting data is stored in `/tmp/mausy5043libs/*.dat` files that are
# subsequently read by `daemons/lnxdiag19d.py`.

TEMPDIR="/tmp/mausy5043libs"
rf="${TEMPDIR}/smartinfo"

# BEWARE
# The disks identified here as `sda`, `sdb` etc. may not necessarily
# be called `/dev/sda`, `/dev/sdb` etc. on the system!!
#sda="wwn-0x50026b723c0d6dd5"  # SSD 50026B723C0D6DD5
#sdb="wwn-0x50014ee261020fce"  # WD-WCC4N5PF96KD
#sdc="wwn-0x50014ee605a043e2"  # WD-WMC4N0K01249
#sdd="wwn-0x50014ee6055a237b"  # WD-WMC4N0J6Y6LW
#sde="wwn-0x50014ee60507b79c"  # WD-WMC4N0E24DVU
#sdf="wwn-0x50014ee262ed6df5"  # WD-WCC4J0JPYS0D
# sdgl=""

function smart1999 {
  # p is the path into the /dev tree
  p="${1}"
  # b is the device id
  b="$(basename ${p})"
  if [[ -e "${p}" ]]; then
    if [[ ! -e "${rf}-${b}-i.dat" ]]; then
      # this is static info, therefore only get it if it's not there.
      smartctl -i "${p}" |awk 'NR>4' > "${rf}-${b}-i.dat"
    fi
    smartctl -A "${p}" |awk 'NR>7' > "${rf}-${b}-A.dat"
    smartctl -H "${p}" |grep 'test result' > "${rf}-${b}-H.dat"
    smartctl -l selftest "${p}" |grep '\# 1' > "${rf}-${b}-l.dat"
    #chmod 744 ${rf}-${b}-*
  fi
}

if [[ ! -d "${TEMPDIR}" ]]; then
  mkdir -m 777 "$TEMPDIR"
fi

touch "${rf}.lock"
find /dev/disk/by-id -name "wwn*" |grep -v "part" > "${TEMPDIR}/smartdisks.txt"
while read p; do
  smart1999 "${p}"
done <"${TEMPDIR}/smartdisks.txt"
rm "${rf}.lock"
