#!/usr/bin/env python3

# daemon15.py measures the size of selected logfiles.
# These are all counters, therefore no averaging is needed.

import configparser
import os
import sys
import syslog
import time
import traceback
import subprocess

from mausy5043libs.libdaemon3 import Daemon
import mausy5043funcs.fileops3 as mf

# constants
DEBUG       = False
IS_JOURNALD = os.path.isfile('/bin/journalctl')
MYID        = "".join(list(filter(str.isdigit, os.path.realpath(__file__).split('/')[-1])))
MYAPP       = os.path.realpath(__file__).split('/')[-3]
NODE        = os.uname()[1]

os.nice(5)

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
    # cycles          = iniconf.getint(inisection, "cycles")
    samplespercycle = iniconf.getint(inisection, "samplespercycle")
    flock           = iniconf.get(inisection, "lockfile")
    fdata           = iniconf.get(inisection, "resultfile")

    # samples         = samplespercycle * cycles          # total number of samples averaged
    sampletime      = reporttime/samplespercycle        # time [s] between samples
    # cycleTime       = samples * sampletime              # time [s] per cycle

    data            = []                                # array for holding sampledata

    while True:
      try:
        starttime   = time.time()

        result      = do_work(reporttime).split(',')

        data        = list(map(int, result))
        mf.syslog_trace("Data     : {0}".format(data),   False, DEBUG)

        # report sample average
        if (starttime % reporttime < sampletime):
          averages  = data
          # averages = sum(data[:]) / len(data)
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

def wc(filename):
    return int(subprocess.check_output(["wc", "-l", filename]).split()[0])

def do_work(interval):
  # 8 #datapoints gathered here
  p0 = p1 = p2 = p3 = p4 = p5 = p6 = p7 = 0

  if IS_JOURNALD:
    # -p, --priority=
    #       Filter output by message priorities or priority ranges. Takes either a single numeric or textual log level (i.e.
    #       between 0/"emerg" and 7/"debug"), or a range of numeric/text log levels in the form FROM..TO. The log levels are the
    #       usual syslog log levels as documented in syslog(3), i.e.  "emerg" (0), "alert" (1), "crit" (2), "err" (3),
    #       "warning" (4), "notice" (5), "info" (6), "debug" (7). If a single log level is specified, all messages with this log
    #       level or a lower (hence more important) log level are shown. If a range is specified, all messages within the range
    #       are shown, including both the start and the end value of the range. This will add "PRIORITY=" matches for the
    #       specified priorities.
    since = "".join(["--since=", str(interval), " seconds ago"])
    p0 = len(subprocess.Popen(["journalctl", since, "--no-pager", "-p", "0..0"], stdout=subprocess.PIPE).stdout.read().splitlines()) - 1
    p1 = len(subprocess.Popen(["journalctl", since, "--no-pager", "-p", "1..1"], stdout=subprocess.PIPE).stdout.read().splitlines()) - 1
    p2 = len(subprocess.Popen(["journalctl", since, "--no-pager", "-p", "2..2"], stdout=subprocess.PIPE).stdout.read().splitlines()) - 1
    p3 = len(subprocess.Popen(["journalctl", since, "--no-pager", "-p", "3..3"], stdout=subprocess.PIPE).stdout.read().splitlines()) - 1
    p4 = len(subprocess.Popen(["journalctl", since, "--no-pager", "-p", "4..4"], stdout=subprocess.PIPE).stdout.read().splitlines()) - 1
    p5 = len(subprocess.Popen(["journalctl", since, "--no-pager", "-p", "5..5"], stdout=subprocess.PIPE).stdout.read().splitlines()) - 1
    p6 = len(subprocess.Popen(["journalctl", since, "--no-pager", "-p", "6..6"], stdout=subprocess.PIPE).stdout.read().splitlines()) - 1
    p7 = len(subprocess.Popen(["journalctl", since, "--no-pager", "-p", "7..7"], stdout=subprocess.PIPE).stdout.read().splitlines()) - 1
  else:
    p0 = wc("/var/log/0emerg.log")
    p1 = wc("/var/log/1alert.log")
    p2 = wc("/var/log/2critical.log")
    p3 = wc("/var/log/3err.log")
    p4 = wc("/var/log/4warn.log")
    p5 = wc("/var/log/5notice.log")
    p6 = wc("/var/log/6info.log")
    p7 = wc("/var/log/7debug.log")

  if p0 < 0:
    p0 = 0
  if p1 < 0:
    p1 = 0
  if p2 < 0:
    p2 = 0
  if p3 < 0:
    p3 = 0
  if p4 < 0:
    p4 = 0
  if p5 < 0:
    p5 = 0
  if p6 < 0:
    p6 = 0
  if p7 < 0:
    p7 = 0

  return '{0}, {1}, {2}, {3}, {4}, {5}, {6}, {7}'.format(p0, p1, p2, p3, p4, p5, p6, p7)

def do_report(result, flock, fdata):
  time.sleep(1)   # sometimes the function is called a sec too soon.
  # Get the time and date in human-readable form and UN*X-epoch...
  outDate   = time.strftime('%Y-%m-%dT%H:%M:%S')
  outEpoch  = int(time.strftime('%s'))
  # round to current minute to ease database JOINs
  outEpoch  = outEpoch - (outEpoch % 60)
  result    = ', '.join(map(str, result))
  ident            = NODE + '@' + str(outEpoch)
  mf.syslog_trace(">>> ID : {0}  -  {1}".format(ident, outDate), False, DEBUG)
  mf.lock(flock)
  with open(fdata, 'a') as f:
    f.write('{0}, {1}, {2}, {3}, {4}\n'.format(outDate, outEpoch, NODE, result, ident))
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
