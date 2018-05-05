#!/usr/bin/env python3

# daemon98.py file post-processor.
# - graphs
# - MySQL queries
# - upload

import configparser
import os
import subprocess
import sys
import syslog
import time
import traceback

from mausy5043libs.libdaemon3 import Daemon
import mausy5043funcs.fileops3 as mf
from random import randrange as rnd

# constants
DEBUG       = False
IS_JOURNALD = os.path.isfile('/bin/journalctl')
MYID        = "".join(list(filter(str.isdigit, os.path.realpath(__file__).split('/')[-1])))
MYAPP       = os.path.realpath(__file__).split('/')[-3]
NODE        = os.uname()[1]
SQLMNT      = rnd(0, 59)
SQLHR       = rnd(0, 23)
SQLHRM      = rnd(0, 59)
SQL_UPDATE_HOUR   = 15   # in minutes (shouldn't be shorter than GRAPH_UPDATE)
SQL_UPDATE_DAY    = 30  # in minutes
SQL_UPDATE_WEEK   = 4   # in hours
SQL_UPDATE_YEAR   = 8   # in hours
GRAPH_UPDATE      = 15   # in minutes

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
    mf.syslog_trace("queries/day.sh  runs every 30 minutes starting at minute {0}".format(SQLMNT), syslog.LOG_DEBUG, DEBUG)
    mf.syslog_trace("queries/week.sh runs every 4th hour  starting  at hour   {0}:{1}".format(SQLHR, SQLHRM), syslog.LOG_DEBUG, DEBUG)
    reporttime      = iniconf.getint(inisection, "reporttime")
    samplespercycle = iniconf.getint(inisection, "samplespercycle")
    flock           = iniconf.get(inisection, "lockfile")

    scriptname      = iniconf.get(inisection, "lftpscript")

    sampletime      = reporttime/samplespercycle         # time [s] between samples

    getsqldata(home, 0, 0, True)
    while True:
      try:
        starttime   = time.time()

        do_stuff(flock, home, scriptname)

        waittime    = sampletime # - (time.time() - starttime)  # - (starttime % sampletime)
        if (waittime > 0):
          mf.syslog_trace("Waiting  : {0}s".format(waittime), False, DEBUG)
          mf.syslog_trace("................................", False, DEBUG)
          time.sleep(waittime)
      except Exception:
        mf.syslog_trace("Unexpected error in run()", syslog.LOG_CRIT, DEBUG)
        mf.syslog_trace(traceback.format_exc(), syslog.LOG_CRIT, DEBUG)
        raise

class Graph(object):
  """docstring for Graph."""
  def __init__(self, updatetime):
    super(Graph, self).__init__()
    self.home = os.environ['HOME']
    self.updatetime = updatetime
    self.command = self.home + '/' + MYAPP + '/mkgraphs.sh'

  def make(self):
    if ((int(time.strftime('%M')) % self.updatetime) == 0):
      mf.syslog_trace("...:  {0}".format(self.command), False, DEBUG)
      return subprocess.call(self.command)
    return 1

def do_stuff(flock, homedir, script):
  # wait 4 seconds for processes to finish
  # unlock(flock)  # remove stale lock
  time.sleep(4)
  minit = int(time.strftime('%M'))
  nowur = int(time.strftime('%H'))

  # Retrieve data from MySQL database
  getsqldata(homedir, minit, nowur, False)

  # Create the graphs based on the MySQL data every 3rd minute
  result = trendgraph.make()
  mf.syslog_trace("...trendgrph:  {0}".format(result), False, DEBUG)
  if (result == 0):
    upload_page(script)

def upload_page(script):
  try:
    # Upload the webpage and graphs
    if os.path.isfile('/tmp/' + MYAPP + '/site/text.md'):
      write_lftp(script)
      cmnd = ['lftp', '-f', script]
      mf.syslog_trace("...:  {0}".format(cmnd), False, DEBUG)
      cmnd = subprocess.check_output(cmnd, timeout=20)
      mf.syslog_trace("...uploadpag:  {0}".format(cmnd), False, DEBUG)
  except subprocess.TimeoutExpired:
    mf.syslog_trace("***TIMEOUT***:  {0}".format(cmnd), syslog.LOG_ERR, DEBUG)
    time.sleep(17*60)             # wait 17 minutes for the router to restart.
    pass
  except subprocess.CalledProcessError:
    mf.syslog_trace("***ERROR***:    {0}".format(cmnd), syslog.LOG_ERR, DEBUG)
    time.sleep(17*60)             # wait 17 minutes for the router to restart.
    pass


def getsqldata(homedir, minit, nowur, nu):
  # minit = int(time.strftime('%M'))
  # nowur = int(time.strftime('%H'))
  # data of last hour is updated every <SQL_UPDATE_HOUR> minutes
  if ((minit % SQL_UPDATE_HOUR) == 0) or nu:
    cmnd = homedir + '/' + MYAPP + '/queries/hour.sh'
    mf.syslog_trace("...:  {0}".format(cmnd), False, DEBUG)
    cmnd = subprocess.call(cmnd)
    mf.syslog_trace("...:  {0}".format(cmnd), False, DEBUG)
  # data of the last day is updated every <SQL_UPDATE_DAY> minutes
  if ((minit % SQL_UPDATE_DAY) == (SQLMNT % SQL_UPDATE_DAY)) or nu:
    cmnd = homedir + '/' + MYAPP + '/queries/day.sh'
    mf.syslog_trace("...:  {0}".format(cmnd), False, DEBUG)
    cmnd = subprocess.call(cmnd)
    mf.syslog_trace("...:  {0}".format(cmnd), False, DEBUG)
  # data of the last week is updated every <SQL_UPDATE_WEEK> hours
  if ((nowur % SQL_UPDATE_WEEK) == (SQLHR % SQL_UPDATE_WEEK) and (minit == SQLHRM)) or nu:
    cmnd = homedir + '/' + MYAPP + '/queries/week.sh'
    mf.syslog_trace("...:  {0}".format(cmnd), False, DEBUG)
    cmnd = subprocess.call(cmnd)
    mf.syslog_trace("...:  {0}".format(cmnd), False, DEBUG)
  # data of the last year is updated at 01:xx
  if (nowur == SQL_UPDATE_YEAR and minit == SQL_UPDATE_DAY) or nu:
    cmnd = homedir + '/' + MYAPP + '/queries/year.sh'
    mf.syslog_trace("...:  {0}".format(cmnd), False, DEBUG)
    cmnd = subprocess.call(cmnd)
    mf.syslog_trace("...:  {0}".format(cmnd), False, DEBUG)

def write_lftp(script):
  with open(script, 'w') as f:
    f.write('# DO NOT EDIT\n')
    f.write('# This file is created automatically by ' + MYAPP + '\n\n')
    f.write('# lftp script\n\n')
    f.write('set cmd:fail-exit yes;\n')
    f.write('open hendrixnet.nl;\n')
    f.write('cd 04.status/;\n')
    f.write('set cmd:fail-exit no;\n')
    f.write('mkdir -p -f _' + NODE + ' ;\n')
    f.write('set cmd:fail-exit yes;\n')
    f.write('cd _' + NODE + ' ;\n')
    f.write('mirror --reverse --delete --verbose=3 -c /tmp/' + MYAPP + '/site/ . ;\n')
    f.write('\n')


if __name__ == "__main__":
  daemon = MyDaemon('/tmp/' + MYAPP + '/' + MYID + '.pid')
  trendgraph = Graph(GRAPH_UPDATE)
  sqldata = SqlDataFetch(SQL_UPDATE_HOUR, SQL_UPDATE_DAY, SQL_UPDATE_WEEK, SQL_UPDATE_YEAR)
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
      mf.syslog_trace("Daemon logging is ON", syslog.LOG_DEBUG, DEBUG)
      daemon.run()
    else:
      print("Unknown command")
      sys.exit(2)
    sys.exit(0)
  else:
    print("usage: {0!s} start|stop|restart|foreground".format(sys.argv[0]))
    sys.exit(2)
