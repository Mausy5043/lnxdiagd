#!/usr/bin/env python3

# daemon11.py measures the CPU temperature.
# uses moving averages

import configparser
import os
import sys
import syslog
import time
import traceback

from mausy5043libs.libdaemon3 import Daemon
import mausy5043funcs.fileops3 as mf

# constants
DEBUG       = False
IS_JOURNALD = os.path.isfile('/bin/journalctl')
MYID        = "".join(list(filter(str.isdigit, os.path.realpath(__file__).split('/')[-1])))
MYAPP       = os.path.realpath(__file__).split('/')[-3]
NODE        = os.uname()[1]

# initialise logging
syslog.openlog(ident=MYAPP, facility=syslog.LOG_LOCAL0)

class MyDaemon(Daemon):
  """Definition of daemon."""
  @staticmethod
  def run():
    iniconf         = configparser.ConfigParser()
    inisection      = MYID
    home            = os.path.expanduser('~')
    s               = iniconf.read(home + '/' + MYAPP + '/config.ini')
    mf.syslog_trace("Config file   : {0}".format(s), False, DEBUG)
    mf.syslog_trace("Options       : {0}".format(iniconf.items(inisection)), False, DEBUG)
    reporttime      = iniconf.getint(inisection, "reporttime")
    cycles          = iniconf.getint(inisection, "cycles")
    samplespercycle = iniconf.getint(inisection, "samplespercycle")
    flock           = iniconf.get(inisection, "lockfile")
    fdata           = iniconf.get(inisection, "resultfile")

    samples         = samplespercycle * cycles      # total number of samples averaged
    sampletime      = reporttime/samplespercycle    # time [s] between samples

    data            = []                            # array for holding sampledata

    try:
      hwdevice      = iniconf.get(inisection, NODE+".hwdevice")
    except configparser.NoOptionError:  # no hwdevice
      mf.syslog_trace(traceback.format_exc(), False, DEBUG)
      sys.exit(0)
    if not os.path.isfile(hwdevice):
      mf.syslog_trace("** Device not found: {0}".format(hwdevice), syslog.LOG_INFO, DEBUG)
      sys.exit(1)

    while True:
      try:
        starttime   = time.time()

        result      = do_work(hwdevice)
        mf.syslog_trace("Result   : {0}".format(result), False, DEBUG)

        data.append(float(result))
        if (len(data) > samples):
          data.pop(0)
        mf.syslog_trace("Data     : {0}".format(data),   False, DEBUG)

        # report sample average
        if (starttime % reporttime < sampletime):
          averages  = format(sum(data[:]) / len(data), '.3f')
          mf.syslog_trace("Averages : {0}".format(averages),  False, DEBUG)
          do_report(averages, flock, fdata)

        waittime    = sampletime - (time.time() - starttime) - (starttime % sampletime)
        if (waittime > 0):
          mf.syslog_trace("Waiting  : {0}s".format(waittime), False, DEBUG)
          mf.syslog_trace("................................", False, DEBUG)
          time.sleep(waittime)
      except Exception:
        mf.syslog_trace("Unexpected error in run()", syslog.LOG_CRIT, DEBUG)
        mf.syslog_trace(traceback.format_exc(), syslog.LOG_CRIT, DEBUG)
        raise

def do_work(fdev):
  Tcpu      = "NaN"
  # Read the CPU temperature
  with open(fdev, 'r') as f:
    Tcpu    = float(f.read().strip('\n'))/1000
  if Tcpu > 85.000:
    # can't believe my sensors. Probably a glitch. Wait a while then measure again
    mf.syslog_trace("Tcpu (HIGH): {0}".format(Tcpu), syslog.LOG_WARNING, DEBUG)
    time.sleep(7)
    with open(fdev, 'r') as f:
      Tcpu  = float(f.read().strip('\n'))/1000
  return Tcpu

def do_report(result, flock, fdata):
  time.sleep(1)   # sometimes the function is called a sec too soon.
  # Get the time and date in human-readable form and UN*X-epoch...
  outDate   = time.strftime('%Y-%m-%dT%H:%M:%S')
  outEpoch  = int(time.strftime('%s'))
  # round to current minute to ease database JOINs
  outEpoch  = outEpoch - (outEpoch % 60)
  ident            = NODE + '@' + str(outEpoch)
  mf.syslog_trace(">>> ID : {0}  -  {1}".format(ident, outDate), False, DEBUG)
  mf.lock(flock)
  with open(fdata, 'a') as f:
    f.write('{0}, {1}, {2}, {3}, {4}\n'.format(outDate, outEpoch, NODE, float(result), ident))
  mf.unlock(flock)


if __name__ == "__main__":
  daemon = MyDaemon('/tmp/' + MYAPP + '/' + MYID + '.pid')
  if len(sys.argv) == 2:
    if 'start' == sys.argv[1]:
      daemon.start()
    elif 'stop' == sys.argv[1]:
      daemon.stop()
    elif 'restart' == sys.argv[1]:
      daemon.restart()
    elif 'debug' == sys.argv[1]:
      # assist with debugging.
      print("Debug-mode started. Use <Ctrl>+C to stop.")
      DEBUG = True
      mf.syslog_trace("Daemon logging is ON", syslog.LOG_DEBUG, DEBUG)
      daemon.run()
    else:
      print("Unknown command")
      sys.exit(2)
    sys.exit(0)
  else:
    print("usage: {0!s} start|stop|restart|debug".format(sys.argv[0]))
    sys.exit(2)
