#!/usr/bin/env python

# Based on previous work by
# Charles Menguy (see: http://stackoverflow.com/questions/10217067/implementing-a-full-python-unix-style-daemon-process)
# and Sander Marechal (see: http://www.jejik.com/articles/2007/02/a_simple_unix_linux_daemon_in_python/)

# Adapted by M.Hendrix [2015]

# daemon11.py measures the CPU temperature.
# uses moving averages

import syslog, traceback
import os, sys, time, math, ConfigParser
from libdaemon import Daemon

# constants
DEBUG       = False
IS_JOURNALD = os.path.isfile('/bin/journalctl')
MYID        = filter(str.isdigit, os.path.realpath(__file__).split('/')[-1])
MYAPP       = os.path.realpath(__file__).split('/')[-2]
NODE        = os.uname()[1]

class MyDaemon(Daemon):
  def run(self):
    iniconf         = ConfigParser.ConfigParser()
    inisection      = MYID
    home            = os.path.expanduser('~')
    s               = iniconf.read(home + '/' + MYAPP + '/config.ini')
    syslog_trace("Config file   : {0}".format(s), False, DEBUG)
    syslog_trace("Options       : {0}".format(iniconf.items(inisection)), False, DEBUG)
    reportTime      = iniconf.getint(inisection, "reporttime")
    cycles          = iniconf.getint(inisection, "cycles")
    samplesperCycle = iniconf.getint(inisection, "samplespercycle")
    flock           = iniconf.get(inisection, "lockfile")
    fdata           = iniconf.get(inisection, "resultfile")

    samples         = samplesperCycle * cycles      # total number of samples averaged
    sampleTime      = reportTime/samplesperCycle    # time [s] between samples
    cycleTime       = samples * sampleTime          # time [s] per cycle

    data            = []                            # array for holding sampledata

    try:
      hwdevice      = iniconf.get(inisection, NODE+".hwdevice")
    except ConfigParser.NoOptionError as e:  #no hwdevice
      syslog_trace("** {0}".format(e.message), False, DEBUG)
      sys.exit(0)
    if not os.path.isfile(hwdevice):
      syslog_trace("** Device not found: {0}".format(hwdevice), syslog.LOG_INFO, DEBUG)
      sys.exit(1)

    while True:
      try:
        startTime   = time.time()

        result      = do_work(hwdevice)
        syslog_trace("Result   : {0}".format(result), False, DEBUG)

        data.append(float(result))
        if (len(data) > samples):
          data.pop(0)
        syslog_trace("Data     : {0}".format(data),   False, DEBUG)

        # report sample average
        if (startTime % reportTime < sampleTime):
          averages  = sum(data[:]) / len(data)
          syslog_trace("Averages : {0}".format(averages),  False, DEBUG)
          do_report(averages, flock, fdata)

        waitTime    = sampleTime - (time.time() - startTime) - (startTime%sampleTime)
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

def do_work(fdev):
  Tcpu      = "NaN"
  # Read the CPU temperature
  with open(fdev,'r') as f:
    Tcpu    = float(f.read().strip('\n'))/1000
  if Tcpu > 75.000:
    # can't believe my sensors. Probably a glitch. Wait a while then measure again
    time.sleep(7)
    with open(fdev,'r') as f:
      Tcpu  = float(f.read().strip('\n'))/1000
      Tcpu  = float(Tcpu) + 0.1
  return Tcpu

def do_report(result, flock, fdata):
  # Get the time and date in human-readable form and UN*X-epoch...
  outDate   = time.strftime('%Y-%m-%dT%H:%M:%S')
  outEpoch  = int(time.strftime('%s'))
  # round to current minute to ease database JOINs
  outEpoch  = outEpoch - (outEpoch % 60)
  lock(flock)
  with open(fdata, 'a') as f:
    f.write('{0}, {1}, {2}, {3}\n'.format(outDate, outEpoch, NODE, float(result)) )
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
