#!/usr/bin/env python

# Based on previous work by
# Charles Menguy (see: http://stackoverflow.com/questions/10217067/implementing-a-full-python-unix-style-daemon-process)
# and Sander Marechal (see: http://www.jejik.com/articles/2007/02/a_simple_unix_linux_daemon_in_python/)

# Adapted by M.Hendrix [2015]

# daemon15.py measures the size of selected logfiles.
# These are all counters, therefore no averaging is needed.

import syslog, traceback
import os, sys, time, math, commands, ConfigParser, platform
from subprocess import check_output
from libdaemon import Daemon

# constants
DEBUG       = False
IS_JOURNALD = os.path.isfile('/bin/journalctl')
MYID        = filter(str.isdigit, os.path.realpath(__file__).split('/')[-1])
MYAPP       = os.path.realpath(__file__).split('/')[-2]
NODE        = platform.node()

os.nice(15)

class MyDaemon(Daemon):
  def run(self):
    iniconf = ConfigParser.ConfigParser()
    inisection = MYID
    home = os.path.expanduser('~')
    s = iniconf.read(home + '/' + MYAPP + '/config.ini')
    syslog_trace("Config file   : {0}".format(s), False, DEBUG)
    syslog_trace("Options       : {0}".format(iniconf.items(inisection)), False, DEBUG)
    reportTime = iniconf.getint(inisection, "reporttime")
    cycles = iniconf.getint(inisection, "cycles")
    samplesperCycle = iniconf.getint(inisection, "samplespercycle")
    flock = iniconf.get(inisection, "lockfile")
    fdata = iniconf.get(inisection, "resultfile")

    samples = samplesperCycle * cycles              # total number of samples averaged
    sampleTime = reportTime/samplesperCycle         # time [s] between samples
    cycleTime = samples * sampleTime                # time [s] per cycle

    data = []                                       # array for holding sampledata

    while True:
      try:
        startTime = time.time()

        result = do_work().split(',')

        data = map(int, result)
        syslog_trace("Data     : {0}".format(data),   False, DEBUG)

        # report sample average
        if (startTime % reportTime < sampleTime):
          averages = data
          #averages = sum(data[:]) / len(data)
          syslog_trace("Averages : {0}".format(averages),  False, DEBUG)
          do_report(averages, flock, fdata)

        waitTime = sampleTime - (time.time() - startTime) - (startTime%sampleTime)
        if (waitTime > 0):
          syslog_trace("Waiting  : {0}s".format(waitTime), False, DEBUG)
          syslog_trace("................................", False, DEBUG)
          time.sleep(waitTime)
      except Exception as e:
        syslog_trace("Unexpected error in run()", syslog.LOG_ALERT, DEBUG)
        syslog_trace("e.message : {0}".format(e.message), syslog.LOG_ALERT, DEBUG)
        syslog_trace("e.__doc__ : {0}".format(e.__doc__), syslog.LOG_ALERT, DEBUG)
        syslog_trace(traceback.format_exc(), syslog.LOG_ALERT, DEBUG)
        raise

def wc(filename):
    return int(check_output(["wc", "-l", filename]).split()[0])

def do_work():
  # 3 #datapoints gathered here
  kernlog=messlog=syslog=0

  if IS_JOURNALD:
    # -p, --priority=
    #       Filter output by message priorities or priority ranges. Takes either a single numeric or textual log level (i.e.
    #       between 0/"emerg" and 7/"debug"), or a range of numeric/text log levels in the form FROM..TO. The log levels are the
    #       usual syslog log levels as documented in syslog(3), i.e.  "emerg" (0), "alert" (1), "crit" (2), "err" (3),
    #       "warning" (4), "notice" (5), "info" (6), "debug" (7). If a single log level is specified, all messages with this log
    #       level or a lower (hence more important) log level are shown. If a range is specified, all messages within the range
    #       are shown, including both the start and the end value of the range. This will add "PRIORITY=" matches for the
    #       specified priorities.
    critlog = commands.getoutput("journalctl --since=00:00:00 --no-pager -p 0..3 |wc -l").split()[0]
    warnlog = commands.getoutput("journalctl --since=00:00:00 --no-pager -p 4 |wc -l").split()[0]
    syslog  = commands.getoutput("journalctl --since=00:00:00 --no-pager |wc -l").split()[0]
  else:
    critlog = wc("/var/log/0emerg.log") + wc("/var/log/1alert.log") + wc("/var/log/2critical.log") + wc("/var/log/3err.log")
    warnlog = wc("/var/log/4warn.log")
    syslog  = wc("/var/log/syslog")
  return '{0}, {1}, {2}'.format(critlog, warnlog, syslog)

def do_report(result, flock, fdata):
  # Get the time and date in human-readable form and UN*X-epoch...
  outDate = time.strftime('%Y-%m-%dT%H:%M:%S')
  outEpoch = int(time.strftime('%s'))
  # round to current minute to ease database JOINs
  outEpoch = outEpoch - (outEpoch % 60)
  result = ', '.join(map(str, result))
  lock(flock)
  with open(fdata, 'a') as f:
    f.write('{0}, {1}\n'.format(outDate, outEpoch, result) )
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
      syslog.syslog(logerr,line)
    if line and out2console:
      print line

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
      print "Debug-mode started. Use <Ctrl>+C to stop."
      DEBUG = True
      syslog_trace("Daemon logging is ON", syslog.LOG_DEBUG, DEBUG)
      daemon.run()
    else:
      print "Unknown command"
      sys.exit(2)
    sys.exit(0)
  else:
    print "usage: {0!s} start|stop|restart|foreground".format(sys.argv[0])
    sys.exit(2)
