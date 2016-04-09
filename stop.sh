#!/bin/bash

# Use stop.sh to stop all daemons in one go
# You can use update.sh to get everything started again.

pushd "$HOME/lnxdiagd"
  source ./includes

  # Check if DIAG daemons are running
  for daemon in $diaglist; do
    # command the daemon to stop regardless if it is running or not.
    eval "./lnxdiag$daemon"d.py stop
    # kill off any rogue daemons by the same name (it happens sometimes)
    if [   $(pgrep -fc "lnxdiag$daemon"d.py) -ne 0 ]; then
      kill $(pgrep -f  "lnxdiag$daemon"d.py)
    fi
    # log the activity
    logger -p user.err -t lnxdiagd "  * Daemon $daemon Stopped."
    # force rm the .pid file
    rm -f "/tmp/lnxdiagd/$daemon.pid"
  done

  # Check if SVC daemons are running
  for daemon in $srvclist; do
    # command the daemon to stop regardless if it is running or not.
    eval "./lnxsvc$daemon"d.py stop
    # kill off any rogue daemons by the same name (it happens sometimes)
    if [   $(pgrep -fc "lnxsvc$daemon"d.py) -ne 0 ]; then
      kill $(pgrep -f  "lnxsvc$daemon"d.py)
    fi
    # log the activity
    logger -p user.err -t lnxdiagd "  * Daemon $daemon Stopped."
    # force rm the .pid file
    rm -f "/tmp/lnxdiagd/$daemon.pid"
  done
popd

echo "To re-start all daemons, use:"
echo "./update.sh"
