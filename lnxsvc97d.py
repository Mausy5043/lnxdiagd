#!/usr/bin/env python

# daemon97.py pushes data to the MySQL-server.
# daemon23 support

import ConfigParser
import glob
# import math
import MySQLdb as mdb
import os
import shutil
# import subprocess
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
    try:                 # Initialise MySQLdb
      consql    = mdb.connect(host='sql.lan', db='domotica', read_default_file='~/.my.cnf')
      if consql.open:    # dB initialised succesfully -> get a cursor on the dB.
        cursql  = consql.cursor()
        cursql.execute("SELECT VERSION()")
        versql  = cursql.fetchone()
        cursql.close()
        logtext = "{0} : {1}".format("Attached to MySQL server", versql)
        syslog.syslog(syslog.LOG_INFO, logtext)
    except mdb.Error as e:
      syslog_trace("Unexpected MySQL error in run(init)", syslog.LOG_ALERT, DEBUG)
      syslog_trace("e.message : {0}".format(e.message), syslog.LOG_ALERT, DEBUG)
      syslog_trace("e.__doc__ : {0}".format(e.__doc__), syslog.LOG_ALERT, DEBUG)
      syslog_trace(traceback.format_exc(), syslog.LOG_ALERT, DEBUG)
      if consql.open:    # attempt to close connection to MySQLdb
        consql.close()
        syslog_trace(" ** Closed MySQL connection in run() **", syslog.LOG_ALERT, DEBUG)
      raise

    iniconf         = ConfigParser.ConfigParser()
    inisection      = MYID
    home            = os.path.expanduser('~')
    s               = iniconf.read(home + '/' + MYAPP + '/config.ini')
    syslog_trace("Config file   : {0}".format(s), False, DEBUG)
    syslog_trace("Options       : {0}".format(iniconf.items(inisection)), False, DEBUG)
    reportTime      = iniconf.getint(inisection, "reporttime")
    # cycles          = iniconf.getint(inisection, "cycles")
    samplesperCycle = iniconf.getint(inisection, "samplespercycle")
    flock           = iniconf.get(inisection, "lockfile")

    # samples         = samplesperCycle * cycles              # total number of samples averaged
    sampleTime      = reportTime/samplesperCycle         # time [s] between samples
    # cycleTime       = samples * sampleTime                # time [s] per cycle

    while True:
      try:
        startTime   = time.time()

        do_sql_data(flock, iniconf, consql)

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
        # attempt to close connection to MySQLdb
        if consql.open:
          consql.close()
          syslog_trace(" *** Closed MySQL connection in run() ***", syslog.LOG_ALERT, DEBUG)
        raise

def cat(filename):
  ret = ""
  if os.path.isfile(filename):
    with open(filename, 'r') as f:
      ret = f.read().strip('\n')
  return ret

def do_writesample(cnsql, cmd, sample):
  fail2write  = False
  dat         = (sample.split(', '))
  try:
    cursql    = cnsql.cursor()
    syslog_trace("   Data: {0}".format(dat), False, DEBUG)
    cursql.execute(cmd, dat)
    cnsql.commit()
    cursql.close()
  except mdb.IntegrityError as e:
    syslog_trace("e.message : {0}".format(e.message), syslog.LOG_ALERT, DEBUG)
    syslog_trace("e.__doc__ : {0}".format(e.__doc__), syslog.LOG_INFO,  DEBUG)
    if cursql:
      cursql.close()
      syslog_trace(" *** Closed MySQL connection in do_writesample() ***", syslog.LOG_ALERT, DEBUG)
      syslog_trace(" Not added to MySQLdb: {0}".format(dat), syslog.LOG_DEBUG, DEBUG)
    pass

  return fail2write

def do_sql_data(flock, inicnfg, cnsql):
  syslog_trace("============================", False, DEBUG)
  syslog_trace("Pushing data to MySQL-server", False, DEBUG)
  syslog_trace("============================", False, DEBUG)
  # set a lock
  lock(flock)
  time.sleep(2)
  # wait for all other processes to release their locks.
  count_internal_locks = 2
  while (count_internal_locks > 1):
    time.sleep(1)
    count_internal_locks = 0
    for fname in glob.glob(r'/tmp/' + MYAPP + '/*.lock'):
      count_internal_locks += 1
    syslog_trace("{0} internal locks exist".format(count_internal_locks), False, DEBUG)
  # endwhile

  for inisect in inicnfg.sections():  # Check each section of the config.ini file
    errsql = False
    try:
      ifile = inicnfg.get(inisect, "resultfile")
      syslog_trace(" < {0}".format(ifile), False, DEBUG)

      try:
        sqlcmd = []
        sqlcmd = inicnfg.get(inisect, "sqlcmd")
        syslog_trace("   {0}".format(sqlcmd), False, DEBUG)

        data = cat(ifile).splitlines()
        if data:
          for entry in range(0, len(data)):
            errsql = do_writesample(cnsql, sqlcmd, data[entry])
          # endfor
        # endif
      except ConfigParser.NoOptionError as e:  # no sqlcmd
        syslog_trace("** {0}".format(e.message), False, DEBUG)
    except ConfigParser.NoOptionError as e:  # no ifile
      syslog_trace("** {0}".format(e.message), False, DEBUG)

    try:
      ofile = inicnfg.get(inisect, "rawfile")
      syslog_trace(" > {0}".format(ofile), False, DEBUG)
      if not errsql:                     # SQL-job was successful or non-existing
        if os.path.isfile(ifile):        # IF resultfile exists
          if not os.path.isfile(ofile):  # AND rawfile does not exist
            shutil.move(ifile, ofile)    # THEN move the file over
    except ConfigParser.NoOptionError as e:  # no ofile
      syslog_trace("** {0}".format(e.message), False, DEBUG)

  # endfor
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
