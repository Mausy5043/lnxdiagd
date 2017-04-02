#!/usr/bin/env python3

# daemon12.py measures the CPU load.
# uses moving averages

import configparser
import os
import sys
import syslog
import time
import traceback

from libdaemon import Daemon

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
    cycles          = iniconf.getint(inisection, "cycles")
    samplespercycle = iniconf.getint(inisection, "samplespercycle")
    flock           = iniconf.get(inisection, "lockfile")
    fdata           = iniconf.get(inisection, "resultfile")

    samples         = samplespercycle * cycles           # total number of samples averaged
    sampletime      = reporttime/samplespercycle         # time [s] between samples
    # cycleTime       = samples * sampletime               # time [s] per cycle

    data            = []                                 # array for holding sampledata
    raw             = [0] * 16                           # array for holding previous /proc/stat data

    while True:
      try:
        starttime     = time.time()

        result, raw   = do_work(raw)
        result        = result.split(',')
        syslog_trace("Result   : {0}".format(result), False, DEBUG)

        data.append(list(map(float, result)))
        if (len(data) > samples):
          data.pop(0)
        syslog_trace("Data     : {0}".format(data),   False, DEBUG)

        # report sample average
        if (starttime % reporttime < sampletime):
          somma       = list(map(sum, list(zip(*data))))
          # not all entries should be float
          # 0.37, 0.18, 0.17, 4, 143, 32147, 3, 4, 93, 0, 0
          averages    = [format(sm / len(data), '.3f') for sm in somma]
          # Report the last measurement for these parameters:
          averages[3] = int(data[-1][3])
          averages[4] = int(data[-1][4])
          averages[5] = int(data[-1][5])
          syslog_trace("Averages : {0}".format(averages),  False, DEBUG)
          do_report(averages, flock, fdata)

        waittime      = sampletime - (time.time() - starttime) - (starttime % sampletime)
        if (waittime > 0):
          syslog_trace("Waiting  : {0}s".format(waittime), False, DEBUG)
          syslog_trace("................................", False, DEBUG)
          time.sleep(waittime)
      except Exception:
        syslog_trace("Unexpected error in run()", syslog.LOG_CRIT, DEBUG)
        syslog_trace(traceback.format_exc(), syslog.LOG_CRIT, DEBUG)
        raise

def do_work(stat1):
  # /proc/loadavg supplies 6 numbers
  with open('/proc/loadavg', 'r') as f:
    outHistLoad = f.read().strip('\n').replace(" ", ", ").replace("/", ", ")

  with open('/proc/stat', 'r') as f:
    stat2 = f.readlines()[0].split()
    # ref: https://www.kernel.org/doc/Documentation/filesystems/proc.txt
    #      http://man7.org/linux/man-pages/man5/proc.5.html
    # -1 "cpu"
    #  0 user: ______ normal processes executing in user mode    0
    #  1 nice: ______ niced processes executing in user mode __ +0
    #  2 system: ____ processes executing in kernel mode         1
    #  3 idle: ______ twiddling thumbs                           2
    #  4 iowait: ____ waiting for I/O to complete                3
    #  5 irq: _______ servicing interrupts ____________________ +3
    #  6 softirq: ___ servicing softirqs                        +3
    #  7 steal: _____ involuntary wait (*)                      +3
    #  8 guest: _____ running a normal guest (**) _____________ +1
    #  9 guest_nice:  running a niced guest (***)               +1
    # (*)   since linux 2.6.11
    # (**)  since linux 2.6.24
    # (***) since linux 2.6.33

  stat2 = list(map(int, stat2[1:]))
  diff0 = [x - y for x, y in zip(stat2, stat1)]
  sum0 = sum(diff0)
  perc = [x / float(sum0) * 100. for x in diff0]

  outCpuUS      = perc[0] + perc[1] + perc[8]
  if (len(perc) == 10):
    outCpuUS += perc[9]
  outCpuSY      = perc[2]
  outCpuID      = perc[3]
  outCpuWA      = perc[4] + perc[5] + perc[6] + perc[7]
  outCpuST = 0   # with the above code this may be omitted.

  return ('{0}, {1}, {2}, {3}, {4}, {5}'.format(outHistLoad, outCpuUS, outCpuSY, outCpuID, outCpuWA, outCpuST), stat2)

def do_report(result, flock, fdata):
  time.sleep(1)   # sometimes the function is called a sec too soon.
  # Get the time and date in human-readable form and UN*X-epoch...
  outDate       = time.strftime('%Y-%m-%dT%H:%M:%S')
  outEpoch      = int(time.strftime('%s'))
  # round to current minute to ease database JOINs
  outEpoch      = outEpoch - (outEpoch % 60)
  result        = ', '.join(map(str, result))
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
