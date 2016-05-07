#!/usr/bin/env python2.7

# daemon98.py file post-processor.

import ConfigParser
import glob
import os
import shutil
import subprocess
import sys
import syslog
import time
import traceback

from libdaemon import Daemon
from random import randrange as rnd

# constants
DEBUG       = False
IS_JOURNALD = os.path.isfile('/bin/journalctl')
MYID        = filter(str.isdigit, os.path.realpath(__file__).split('/')[-1])
MYAPP       = os.path.realpath(__file__).split('/')[-2]
NODE        = os.uname()[1]
SQLMNT      = rnd(0, 59)
SQLHR       = rnd(0, 23)

class MyDaemon(Daemon):
  def run(self):
    iniconf         = ConfigParser.ConfigParser()
    inisection      = MYID
    home            = os.path.expanduser('~')
    s               = iniconf.read(home + '/' + MYAPP + '/config.ini')
    syslog_trace("Config file   : {0}".format(s), False, DEBUG)
    syslog_trace("Options       : {0}".format(iniconf.items(inisection)), False, DEBUG)
    syslog_trace("getsqlday.sh  runs every 30 minutes starting at minute {0}".format(SQLMNT), syslog.LOG_DEBUG, DEBUG)
    syslog_trace("getsqlweek.sh runs every 4th hour  starting  at hour   {0}".format(SQLHR), syslog.LOG_DEBUG, DEBUG)
    reportTime      = iniconf.getint(inisection, "reporttime")
    samplesperCycle = iniconf.getint(inisection, "samplespercycle")
    flock           = iniconf.get(inisection, "lockfile")

    scriptname      = iniconf.get(inisection, "lftpscript")

    sampleTime      = reportTime/samplesperCycle         # time [s] between samples
    getsqldata(home, True)
    while True:
      try:
        startTime   = time.time()

        do_mv_data(flock, home, scriptname)

        waitTime    = sampleTime - (time.time() - startTime) - (startTime % sampleTime)
        if (waitTime > 0):
          syslog_trace("Waiting  : {0}s".format(waitTime), False, DEBUG)
          syslog_trace("................................", False, DEBUG)
          time.sleep(waitTime)
      except Exception as e:
        syslog_trace("Unexpected error in run()", syslog.LOG_CRIT, DEBUG)
        syslog_trace("e.message : {0}".format(e.message), syslog.LOG_CRIT, DEBUG)
        syslog_trace("e.__doc__ : {0}".format(e.__doc__), syslog.LOG_CRIT, DEBUG)
        syslog_trace(traceback.format_exc(), syslog.LOG_CRIT, DEBUG)
        raise

def do_mv_data(flock, homedir, script):
  # wait 15 seconds for processes to finish
  unlock(flock)  # remove stale lock
  t0 = time.time()

  getsqldata(homedir, False)

  cmnd = homedir + '/' + MYAPP + '/graphday.sh'
  syslog_trace("...:  {0}".format(cmnd), False, DEBUG)
  cmnd = subprocess.call(cmnd)
  syslog_trace("...:  {0}".format(cmnd), False, DEBUG)

  if os.path.isfile('/tmp/' + MYAPP + '/site/text.md'):
    write_lftp(script)
    cmnd = ['lftp', '-f', script]
    syslog_trace("...:  {0}".format(cmnd), False, DEBUG)
    cmnd = subprocess.call(cmnd)
    syslog_trace("...:  {0}".format(cmnd), False, DEBUG)

  waitTime = 15 - (time.time() - t0)
  if waitTime > 0:
    time.sleep(waitTime)
  lock(flock)
  # wait for all other processes to release their locks.
  count_internal_locks = 2
  while (count_internal_locks > 1):
    time.sleep(1)
    count_internal_locks = 0
    for fname in glob.glob(r'/tmp/' + MYAPP + '/*.lock'):
      count_internal_locks += 1
    syslog_trace("{0} internal locks exist".format(count_internal_locks), False, DEBUG)
  # endwhile

  for fname in glob.glob(r'/tmp/' + MYAPP + '/*.csv'):
    syslog_trace("...moving data {0}".format(fname), False, DEBUG)
    shutil.move(fname, fname+".DEAD")

  # for fname in glob.glob(r'/tmp/' + MYAPP + '/*.png'):
  #  syslog_trace("...moving graph {0}".format(fname), False, DEBUG)
  #  shutil.move(fname, fname+".DEAD")

  unlock(flock)

def getsqldata(homedir, nu):
  minit = int(time.strftime('%M'))
  nowur = int(time.strftime('%H'))
  # data of last hour is updated every minute
  cmnd = homedir + '/' + MYAPP + '/getsqlhour.sh'
  syslog_trace("...:  {0}".format(cmnd), False, DEBUG)
  cmnd = subprocess.call(cmnd)
  syslog_trace("...:  {0}".format(cmnd), False, DEBUG)
  # data of the last day is updated every 30 minutes
  if ((minit % 30) == (SQLMNT % 30)) or nu:
    cmnd = homedir + '/' + MYAPP + '/getsqlday.sh'
    syslog_trace("...:  {0}".format(cmnd), False, DEBUG)
    cmnd = subprocess.call(cmnd)
    syslog_trace("...:  {0}".format(cmnd), False, DEBUG)
    # dat of the last week is updated every 4 hours
    if ((nowur % 4) == (SQLHR % 4)) or nu:
      cmnd = homedir + '/' + MYAPP + '/getsqlweek.sh'
      syslog_trace("...:  {0}".format(cmnd), False, DEBUG)
      cmnd = subprocess.call(cmnd)
      syslog_trace("...:  {0}".format(cmnd), False, DEBUG)

def write_lftp(script):
  with open(script, 'w') as f:
    f.write('# DO NOT EDIT\n')
    f.write('# This file is created automatically by ' + MYAPP + '\n\n')
    f.write('# lftp script\n\n')
    f.write('open hendrixnet.nl;\n')
    f.write('cd /public_html/grav/user/pages/04.status/;\n')
    f.write('mkdir -p -f _' + NODE + ' ;\n')
    f.write('cd _' + NODE + ' ;\n')
    f.write('mirror --reverse --delete --verbose=3 -c /tmp/' + MYAPP + '/site/ . ;\n')
    f.write('\n')

def lock(fname):
  open(fname, 'a').close()
  syslog_trace("!..LOCK", False, DEBUG)

def unlock(fname):
  if os.path.isfile(fname):
    os.remove(fname)
    syslog_trace("!..UNLOCK", False, DEBUG)

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
