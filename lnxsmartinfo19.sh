#! /bin/bash

# This script is executed periodically by a cronjob.
# It prevents the use of repeated `sudo smartctl...` commands
# The resulting data is stored in `/tmp/mausy5043libs/*.dat` files that are
# subsequently read by `daemons/lnxdiag19d.py`.

TEMPDIR="/tmp/mausy5043libs"
rf="${TEMPDIR}/smartinfo"

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
