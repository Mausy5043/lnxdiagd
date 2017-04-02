#!/usr/bin/env python3

# daemon14.py measures the memory usage.
# These are all counters, therefore no averaging is needed.

import configparser
import os
import sys
import syslog
import time
import traceback

from mausy5043libs.libdaemon3 import Daemon

# constants
DEBUG       = False
IS_JOURNALD = os.path.isfile('/bin/journalctl')
MYID        = "".join(list(filter(str.isdigit, os.path.realpath(__file__).split('/')[-1])))
MYAPP       = os.path.realpath(__file__).split('/')[-2]
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
    syslog_trace("Config file   : {0}".format(s), False, DEBUG)
    syslog_trace("Options       : {0}".format(iniconf.items(inisection)), False, DEBUG)
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

        result      = do_work().split(',')

        data        = list(map(int, result))
        syslog_trace("Data     : {0}".format(data),   False, DEBUG)

        # report sample average
        if (starttime % reporttime < sampletime):
          averages  = data
          # averages = sum(data[:]) / len(data)
          syslog_trace("Averages : {0}".format(averages),  False, DEBUG)
          do_report(averages, flock, fdata)

        waittime    = sampletime - (time.time() - starttime) - (starttime % sampletime)
        if (waittime > 0):
          syslog_trace("Waiting  : {0}s".format(waittime), False, DEBUG)
          syslog_trace("................................", False, DEBUG)
          time.sleep(waittime)
      except Exception:
        syslog_trace("Unexpected error in run()", syslog.LOG_CRIT, DEBUG)
        syslog_trace(traceback.format_exc(), syslog.LOG_CRIT, DEBUG)
        raise

def cat(filename):
  ret = ""
  if os.path.isfile(filename):
    with open(filename, 'r') as f:
      ret = f.read().strip('\n')
  return ret

def do_work():
  # 8 #datapoints gathered here
  # memory /proc/meminfo
  # total     = MemTotal
  # free      = MemFree - (Buffers + Cached)
  # inUse     = (MemTotal - MemFree) - (Buffers + Cached)
  # swaptotal = SwapTotal
  # swapUse   = SwapTotal - SwapFree
  # ref: http://thoughtsbyclayg.blogspot.nl/2008/09/display-free-memory-on-linux-ubuntu.html
  # ref: http://serverfault.com/questions/85470/meaning-of-the-buffers-cache-line-in-the-output-of-free

  out = cat("/proc/meminfo").splitlines()
  for line in range(0, len(out)-1):
    mem = out[line].split()
    if mem[0] == 'MemFree:':
      outMemFree = int(mem[1])
    elif mem[0] == 'MemTotal:':
      outMemTotal = int(mem[1])
    elif mem[0] == 'Buffers:':
      outMemBuf = int(mem[1])
    elif mem[0] == 'Cached:':
      outMemCache = int(mem[1])
    elif mem[0] == 'SwapTotal:':
      outMemSwapTotal = int(mem[1])
    elif mem[0] == "SwapFree:":
      outMemSwapFree = int(mem[1])

  outMemUsed = outMemTotal - (outMemFree + outMemBuf + outMemCache)
  outMemSwapUsed = outMemSwapTotal - outMemSwapFree

  return '{0}, {1}, {2}, {3}, {4}, {5}, {6}, {7}'.format(outMemTotal, outMemUsed, outMemBuf, outMemCache, outMemFree, outMemSwapTotal, outMemSwapFree, outMemSwapUsed)

def do_report(result, flock, fdata):
  time.sleep(1)   # sometimes the function is called a sec too soon.
  # Get the time and date in human-readable form and UN*X-epoch...
  outDate     = time.strftime('%Y-%m-%dT%H:%M:%S')
  outEpoch    = int(time.strftime('%s'))
  # round to current minute to ease database JOINs
  outEpoch    = outEpoch - (outEpoch % 60)
  result      = ', '.join(map(str, result))
  ident            = NODE + '@' + str(outEpoch)
  syslog_trace(">>> ID : {0}  -  {1}".format(ident, outDate), False, DEBUG)
  lock(flock)
  with open(fdata, 'a') as f:
    f.write('{0}, {1}, {2}, {3}, {4}\n'.format(outDate, outEpoch, NODE, result, ident))
  unlock(flock)

def lock(fname):
  open(fname, 'a').close()

def unlock(fname):
  if os.path.isfile(fname):
    os.remove(fname)

def syslog_trace(trace, logerr, out2console):
  # Log a python stack trace to syslog
  log_lines = trace.split('\n')
  for line in log_lines:
    if line and logerr:
      syslog.syslog(logerr, line)
    if line and out2console:
      print(line)


if __name__ == "__main__":
  daemon = MyDaemon('/tmp/' + MYAPP + '/' + MYID + '.pid')
  if len(sys.argv) == 2:
    if 'start' == sys.argv[1]:
      daemon.start()
    elif 'stop' == sys.argv[1]:
      daemon.stop()
    elif 'restart' == sys.argv[1]:
      daemon.restart()
    elif 'foreground' == sys.argv[1]:
      # assist with debugging.
      print("Debug-mode started. Use <Ctrl>+C to stop.")
      DEBUG = True
      syslog_trace("Daemon logging is ON", syslog.LOG_DEBUG, DEBUG)
      daemon.run()
    else:
      print("Unknown command")
      sys.exit(2)
    sys.exit(0)
  else:
    print("usage: {0!s} start|stop|restart|foreground".format(sys.argv[0]))
    sys.exit(2)
