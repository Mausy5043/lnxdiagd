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

DEBUG = False
IS_JOURNALD = os.path.isfile('/bin/journalctl')
leaf = os.path.realpath(__file__).split('/')[-2]

class MyDaemon(Daemon):
  def run(self):
    iniconf = ConfigParser.ConfigParser()
    inisection = "11"
    home = os.path.expanduser('~')
    s = iniconf.read(home + '/' + leaf + '/config.ini')
    if DEBUG: 
      print "config file : {0}".format(s)
      print iniconf.items(inisection)
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

        result = do_work()
        if DEBUG: print result

        data.append(float(result))
        if (len(data) > samples):data.pop(0)

        # report sample average
        if (startTime % reportTime < sampleTime):
          averages = sum(data[:]) / len(data)
          if DEBUG: 
            print data
            print averages
          do_report(averages, flock, fdata)

        waitTime = sampleTime - (time.time() - startTime) - (startTime%sampleTime)
        if (waitTime > 0):
          if DEBUG: print "Waiting {0} s".format(waitTime)
          time.sleep(waitTime)
      except Exception as e:
        if DEBUG:
          print "Unexpected error:"
          print e.message
        syslog.syslog(syslog.LOG_ALERT,e.__doc__)
        syslog_trace(traceback.format_exc())
        raise

def do_work():
  Tcpu = "NaN"
  # Read the CPU temperature
  fi = "/sys/class/hwmon/hwmon0/device/temp1_input"
  with open(fi,'r') as f:
    Tcpu = float(f.read().strip('\n'))/1000
  if Tcpu > 75.000:
    # can't believe my sensors. Probably a glitch. Wait a while then measure again
    time.sleep(7)
    fi = "/sys/class/hwmon/hwmon0/device/temp1_input"
    with open(fi,'r') as f:
      Tcpu = float(f.read().strip('\n'))/1000
      Tcpu = float(Tcpu) + 0.1

  return Tcpu

def do_report(result, flock, fdata):
  # Get the time and date in human-readable form and UN*X-epoch...
  outDate = time.strftime('%Y-%m-%dT%H:%M:%S, %s')
  lock(flock)
  with open(fdata, 'a') as f:
    f.write('{0}, {1}\n'.format(outDate, float(result)) )
  unlock(flock)

def lock(fname):
  open(fname, 'a').close()

def unlock(fname):
  if os.path.isfile(fname):
    os.remove(fname)

def syslog_trace(trace):
  # Log a python stack trace to syslog
  log_lines = trace.split('\n')
  for line in log_lines:
    if line:
      syslog.syslog(syslog.LOG_ALERT,line)

if __name__ == "__main__":

  if not os.path.isfile('/sys/class/hwmon/hwmon0/device/temp1_input'):
    print "Hardware missing!"
    syslog.syslog(syslog.LOG_ALERT,"Hardware missing!")
    sys.exit(2)

  daemon = MyDaemon('/tmp/' + leaf + '/11.pid')
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
      if DEBUG:
        logtext = "Daemon logging is ON"
        syslog.syslog(syslog.LOG_DEBUG, logtext)
      daemon.run()
    else:
      print "Unknown command"
      sys.exit(2)
    sys.exit(0)
  else:
    print "usage: {0!s} start|stop|restart|foreground".format(sys.argv[0])
    sys.exit(2)
