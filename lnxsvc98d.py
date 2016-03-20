#!/usr/bin/env python

# daemon98.py uploads data to the server.

import ConfigParser
import glob
import os
import shutil
import sys
import syslog
import time
import traceback

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
    # cycles          = iniconf.getint(inisection, "cycles")
    samplesperCycle = iniconf.getint(inisection, "samplespercycle")
    # flock           = iniconf.get(inisection, "lockfile")

    # samples         = samplesperCycle * cycles           # total number of samples averaged
    sampleTime      = reportTime/samplesperCycle         # time [s] between samples
    # cycleTime       = samples * sampleTime               # time [s] per cycle

    mount_path      = '/mnt/share1/'
    remote_path     = mount_path + NODE
    # remote_lock     = remote_path + '/client.lock'
    while True:
      try:
        startTime   = time.time()

        if os.path.ismount(mount_path):
          do_mv_data(remote_path)

        waitTime    = sampleTime - (time.time() - startTime) - (startTime % sampleTime)
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

def do_mv_data(rpath):
  hostlock              = rpath + '/host.lock'
  clientlock            = rpath + '/client.lock'
  count_internal_locks  = 1

  # wait 5 seconds for processes to finish
  time.sleep(5)

  while os.path.isfile(hostlock):
    syslog_trace("...hostlock exists", syslog.LOG_DEBUG, DEBUG)
    # wait while the server has locked the directory
    time.sleep(1)

  # server already sets the client.lock. Do it anyway.
  lock(clientlock)
  syslog_trace("!..LOCK", False, DEBUG)

  # prevent race conditions
  while os.path.isfile(hostlock):
    syslog_trace("...hostlock exists (again???) !!", syslog.LOG_DEBUG, DEBUG)
    # wait while the server has locked the directory
    time.sleep(1)

  while (count_internal_locks > 0):
    time.sleep(1)
    count_internal_locks = 0
    for fname in glob.glob(r'/tmp/' + MYAPP + '/*.lock'):
      count_internal_locks += 1
    syslog_trace("...{0} internal locks exist".format(count_internal_locks), False, DEBUG)

  for fname in glob.glob(r'/tmp/' + MYAPP + '/*.csv'):
    if os.path.isfile(clientlock) and not (os.path.isfile(rpath + "/" + os.path.split(fname)[1])):
      syslog_trace("...moving data {0}".format(fname), False, DEBUG)
      shutil.move(fname, fname+".DEAD")

  for fname in glob.glob(r'/tmp/' + MYAPP + '/*.png'):
    if os.path.isfile(clientlock) and not (os.path.isfile(rpath + "/" + os.path.split(fname)[1])):
      syslog_trace("...moving graph {0}".format(fname), False, DEBUG)
      shutil.move(fname, fname+".DEAD")

  unlock(clientlock)
  syslog_trace("!..UNLOCK", False, DEBUG)

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
