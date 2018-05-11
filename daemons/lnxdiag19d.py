#!/usr/bin/env python3

# measure the temperature of the diskarray.

import configparser
import os
import sys
import syslog
import time
import traceback

from mausy5043libs.libdaemon3 import Daemon
from mausy5043libs.libsmart3 import SmartDisk
import mausy5043funcs.fileops3 as mf

# constants
DEBUG       = False
IS_JOURNALD = os.path.isfile('/bin/journalctl')
MYID        = "".join(list(filter(str.isdigit, os.path.realpath(__file__).split('/')[-1])))
MYAPP       = os.path.realpath(__file__).split('/')[-3]
NODE        = os.uname()[1]

# BEWARE
# The disks identified here as `sda`, `sdb` etc. may not necessarily
# be called `/dev/sda`, `/dev/sdb` etc. on the system!!

sda = SmartDisk("wwn-0x50026b723c0d6dd5")  # SSD 50026B723C0D6DD5
sdb = SmartDisk("wwn-0x50014ee261020fce")  # WD-WCC4N5PF96KD
sdc = SmartDisk("wwn-0x50014ee605a043e2")  # WD-WMC4N0K01249
sdd = SmartDisk("wwn-0x50014ee6055a237b")  # WD-WMC4N0J6Y6LW
sde = SmartDisk("wwn-0x50014ee60507b79c")  # WD-WMC4N0E24DVU
# sdf = wwn-0x50014ee262ed6df5
# sdg =

DEBUG = False
leaf = os.path.realpath(__file__).split('/')[-2]

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

    while True:
      try:
        starttime = time.time()

        result        = do_work()
        result        = result.split(',')
        mf.syslog_trace("Result   : {0}".format(result), False, DEBUG)

        data.append(list(map(float, result)))
        if (len(data) > samples):
          data.pop(0)
        mf.syslog_trace("Data     : {0}".format(data),   False, DEBUG)

        # report sample average
        if (starttime % reporttime < sampletime):
          somma       = list(map(sum, list(zip(*data))))
          # not all entries should be float
          # 0.37, 0.18, 0.17, 4, 143, 32147, 3, 4, 93, 0, 0
          averages    = [format(sm / len(data), '.3f') for sm in somma]
          # Report the last measurement for these parameters:
          mf.syslog_trace("Averages : {0}".format(averages),  False, DEBUG)
          do_report(averages, flock, fdata)

        waittime    = sampletime - (time.time() - starttime) - (starttime % sampletime)
        if (waittime > 0):
          mf.syslog_trace("Waiting  : {0}s".format(waittime), False, DEBUG)
          mf.syslog_trace("................................", False, DEBUG)
          time.sleep(waittime)
      except ValueError:
        mf.syslog_trace("Waiting for S.M.A.R.T. data..", syslog.LOG_DEBUG, DEBUG)
        time.sleep(60)
        pass
      except Exception:
        mf.syslog_trace("Unexpected error in run()", syslog.LOG_CRIT, DEBUG)
        mf.syslog_trace(traceback.format_exc(), syslog.LOG_CRIT, DEBUG)
        raise

def do_work():
  # 5 datapoints gathered here
  #
  sda.smart()
  sdb.smart()
  sdc.smart()
  sdd.smart()
  sde.smart()
  # sdf.smart()
  # sdg.smart()

  # disktemperature
  Tsda = sda.getdata('194')
  Tsdb = sdb.getdata('194')
  Tsdc = sdc.getdata('194')
  Tsdd = sdd.getdata('194')
  Tsde = sde.getdata('194')
  # Tsdf = 0
  # Tsdg = 0

  mf.syslog_trace('{0}, {1}, {2}, {3}, {4}'.format(Tsda, Tsdb, Tsdc, Tsdd, Tsde), False, DEBUG)
  return '{0}, {1}, {2}, {3}, {4}'.format(Tsda, Tsdb, Tsdc, Tsdd, Tsde)

def do_report(result, flock, fdata):
  time.sleep(1)   # sometimes the function is called a sec too soon.
  # Get the time and date in human-readable form and UN*X-epoch...
  outDate       = time.strftime('%Y-%m-%dT%H:%M:%S')
  outEpoch      = int(time.strftime('%s'))
  # round to current minute to ease database JOINs
  outEpoch      = outEpoch - (outEpoch % 60)
  # ident            = NODE + '@' + str(outEpoch)
  mf.lock(flock)
  with open(fdata, 'a') as f:
    f.write('{0}, {1}, {2}, {3}, {4}, {5}\n'.format(outDate, outEpoch, NODE, sda.id, result[0], sda.id + '@' + str(outEpoch)))
    f.write('{0}, {1}, {2}, {3}, {4}, {5}\n'.format(outDate, outEpoch, NODE, sdb.id, result[1], sdb.id + '@' + str(outEpoch)))
    f.write('{0}, {1}, {2}, {3}, {4}, {5}\n'.format(outDate, outEpoch, NODE, sdc.id, result[2], sdc.id + '@' + str(outEpoch)))
    f.write('{0}, {1}, {2}, {3}, {4}, {5}\n'.format(outDate, outEpoch, NODE, sdd.id, result[3], sdd.id + '@' + str(outEpoch)))
    f.write('{0}, {1}, {2}, {3}, {4}, {5}\n'.format(outDate, outEpoch, NODE, sde.id, result[4], sde.id + '@' + str(outEpoch)))
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
