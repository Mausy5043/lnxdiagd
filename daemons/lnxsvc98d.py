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
from mausy5043libs.libgraph3 import Graph
from mausy5043libs.libsqldata3 import SqlDataFetch
import mausy5043funcs.fileops3 as mf

# constants
DEBUG       = False
IS_JOURNALD = os.path.isfile('/bin/journalctl')
MYID        = "".join(list(filter(str.isdigit, os.path.realpath(__file__).split('/')[-1])))
MYAPP       = os.path.realpath(__file__).split('/')[-3]
NODE        = os.uname()[1]
HOME        = os.environ['HOME']
GRAPH_UPDATE      = 10   # in minutes
SQL_UPDATE_HOUR   = GRAPH_UPDATE  # in minutes (shouldn't be shorter than GRAPH_UPDATE)
SQL_UPDATE_DAY    = 27  # in minutes
SQL_UPDATE_WEEK   = 4   # in hours
SQL_UPDATE_YEAR   = 8   # in hours

# initialise logging
syslog.openlog(ident=MYAPP, facility=syslog.LOG_LOCAL0)

class MyDaemon(Daemon):
  """Definition of daemon."""
  @staticmethod
  def run():
    iniconf         = configparser.ConfigParser()
    inisection      = MYID
    s               = iniconf.read(HOME + '/' + MYAPP + '/config.ini')
    mf.syslog_trace("Config file   : {0}".format(s), False, DEBUG)
    mf.syslog_trace("Options       : {0}".format(iniconf.items(inisection)), False, DEBUG)
    reporttime      = iniconf.getint(inisection, "reporttime")
    samplespercycle = iniconf.getint(inisection, "samplespercycle")
    flock           = iniconf.get(inisection, "lockfile")
    scriptname      = iniconf.get(inisection, "lftpscript")

    sampletime      = reporttime/samplespercycle         # time [s] between samples
    sqldata.fetch()
    if (trendgraph.make() == 0):
      upload_page(scriptname)
    while True:
      try:
        # starttime   = time.time()

        do_stuff(flock, HOME, scriptname)
        # not syncing to top of the minute
        waittime    = sampletime  # - (time.time() - starttime) - (starttime % sampletime)
        if (waittime > 0):
          mf.syslog_trace("Waiting  : {0}s".format(waittime), False, DEBUG)
          mf.syslog_trace("................................", False, DEBUG)
          time.sleep(waittime)
      except Exception:
        mf.syslog_trace("Unexpected error in run()", syslog.LOG_CRIT, DEBUG)
        mf.syslog_trace(traceback.format_exc(), syslog.LOG_CRIT, DEBUG)
        raise

def do_stuff(flock, homedir, script):
  # wait 4 seconds for processes to finish
  time.sleep(4)

  # Retrieve data from MySQL database
  # CLAIM
  # CHECK
  result = sqldata.fetch()
  mf.syslog_trace("...datafetch:  {0}".format(result), False, DEBUG)
  # RELEASE

  # Create the graphs based on the MySQL data
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
  if len(sys.argv) == 2:
    if 'debug' == sys.argv[1]:
      DEBUG = True

  daemon = MyDaemon('/tmp/' + MYAPP + '/' + MYID + '.pid')
  trendgraph = Graph(HOME + '/' + MYAPP + '/mkgraphs.sh', GRAPH_UPDATE, DEBUG)
  sqldata = SqlDataFetch(HOME + '/' + MYAPP + '/queries', '/srv/semaphores', SQL_UPDATE_HOUR, SQL_UPDATE_DAY, SQL_UPDATE_WEEK, SQL_UPDATE_YEAR, DEBUG)

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
