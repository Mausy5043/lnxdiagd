#!/usr/bin/env python3

# daemon21d.py creates a graph.

import configparser
import datetime
import MySQLdb as mdb
import os
# import platform
# import shutil
import sys
import syslog
import time
import traceback

from libdaemon import Daemon

import numpy as np
import matplotlib as mpl
mpl.use("Agg", warn=True)         # activate Anti-Grain Geometry library before importing pyplot
import matplotlib.pyplot as plt   #noqa

# constants
PLOT_TITLE      = "System Temperature"
PLOT_Y1LABEL    = "Temperature [degC]"
PLOT_Y2LABEL    = ""

DEBUG           = False
IS_JOURNALD     = os.path.isfile('/bin/journalctl')
MYID            = "".join(list(filter(str.isdigit, os.path.realpath(__file__).split('/')[-1])))
MYAPP           = os.path.realpath(__file__).split('/')[-2]
NODE            = os.uname()[1]

LOCATEDMONDAYS  = mpl.dates.WeekdayLocator(mpl.dates.MONDAY)      # find all mondays
LOCATEDMONTHS   = mpl.dates.MonthLocator()                        # find all months
LOCATEDDAYS     = mpl.dates.DayLocator()                          # find all days
LOCATEDHOURS    = mpl.dates.HourLocator()                         # find all hours
LOCATEDMINUTES  = mpl.dates.MinuteLocator()                       # find all minutes


def timeme(method):
  """
  Execution timer.
  Used as decoration to determine execution time of functions.
  For profiling and debugging purposes.
  """
  def wrapper(*args, **kw):
      starttime = int(round(time.time() * 1000))
      result = method(*args, **kw)
      endtime = int(round(time.time() * 1000))
      print(endtime - starttime, 'ms')
      return result
  return wrapper


class MyDaemon(Daemon):
  """Definition of daemon."""
  def run(self):
    """Overload definition of run."""
    try:                 # Initialise MySQLdb
      consql    = mdb.connect(host='sql.lan', db='domotica', read_default_file='~/.my.cnf')
      if consql.open:                           # dB initialised successfully
        cursql  = consql.cursor()               # get a cursor on the dB.
        cursql.execute("SELECT VERSION()")
        versql  = cursql.fetchone()
        cursql.close()
        logtext = "{0} : {1}".format("Attached to MySQL server", versql)
        syslog.syslog(syslog.LOG_INFO, logtext)
    except mdb.Error:
      syslog_trace("Unexpected MySQL error in run(init)", syslog.LOG_CRIT, DEBUG)
      syslog_trace(traceback.format_exc(), syslog.LOG_CRIT, DEBUG)
      if consql.open:                           # attempt to close connection to MySQLdb
        consql.close()
        syslog_trace("** Closed MySQL connection in run(init) **", syslog.LOG_CRIT, DEBUG)
      raise

    iniconf         = configparser.ConfigParser()
    inisection      = MYID
    home            = os.path.expanduser('~')
    s               = iniconf.read(home + '/' + MYAPP + '/config.ini')
    syslog_trace("Config file   : {0}".format(s), False, DEBUG)
    syslog_trace("Options       : {0}".format(iniconf.items(inisection)), False, DEBUG)
    reportTime      = iniconf.getint(inisection, "reporttime")
    samplesperCycle = iniconf.getint(inisection, "samplespercycle")
    flock           = iniconf.get(inisection, "lockfile")
    sampleTime      = reportTime/samplesperCycle        # time [s] between samples

    init_axes()
    do_main(flock, True, consql)  # get all data and graphs on start-up

    while True:
      try:
        startTime   = time.time()

        do_main(flock, False, consql)

        waitTime    = sampleTime - (time.time() - startTime) - (startTime % sampleTime)
        if (waitTime > 0):
          syslog_trace("Waiting  : {0}s".format(waitTime), False, DEBUG)
          syslog_trace("................................", False, DEBUG)
          time.sleep(waitTime)
      except Exception:  # Gotta catch em all
        syslog_trace("Unexpected error in run()", syslog.LOG_CRIT, DEBUG)
        syslog_trace(traceback.format_exc(), syslog.LOG_CRIT, DEBUG)
        raise

@timeme
def update_hour_query(consql, xdata, ydata, queryminutes):
  """Query the database and update the data for the past hour"""
  syslog_trace("* Get update of {0} samples for past hour".format(queryminutes), False, DEBUG)
  divider = 60
  sqlcmd = ("SELECT MIN(sample_time), AVG(temperature) "
            "FROM systemp "
            "WHERE (sample_time >= NOW() - INTERVAL %s MINUTE) AND (host = %s) "
            "GROUP BY (sample_epoch DIV %s);")
  sqldata = (queryminutes, NODE, divider)
  try:
    cursql  = consql.cursor()               # get a cursor on the dB.
    cursql.execute(sqlcmd, sqldata)
    consql.commit()
    data  = cursql.fetchall()
    cursql.close()
  except mdb.IntegrityError as e:
    syslog_trace("DB error : {0}".format(e.__str__), syslog.LOG_ERR,  DEBUG)
    if cursql:
      cursql.close()
      syslog_trace(" *** Closed MySQL connection in do_writesample() ***", syslog.LOG_ERR, DEBUG)
      syslog_trace(" Execution of MySQL command {0} FAILED!".format(sqlcmd), syslog.LOG_INFO, DEBUG)
    pass

  for i, j in (data):
    if len(xdata) > 0:
      previ = xdata[-1]
    else:
      previ = 0
    i = mpl.dates.date2num(i)
    if i > previ:
      xdata = np.append(xdata, i)
      ydata = np.append(ydata, float(j))

  while len(xdata) > 70:
    xdata = xdata[1:]
  while len(ydata) > len(xdata):
    ydata = ydata[1:]

  return xdata, ydata

@timeme
def update_day_query(consql, xdata, ydata, queryhours):
  """Query the database and update the data for the past day"""
  syslog_trace("* Get update of {0} samples for past day".format(queryhours), False, DEBUG)
  divider = 1800
  sqlcmd = ("SELECT MIN(sample_time), MIN(temperature), AVG(temperature), MAX(temperature) "
            "FROM systemp "
            "WHERE (sample_time >= NOW() - INTERVAL %s HOUR) AND (host = %s) "
            "GROUP BY (sample_epoch DIV %s);")
  sqldata = (queryhours, NODE, divider)
  try:
    cursql  = consql.cursor()               # get a cursor on the dB.
    cursql.execute(sqlcmd, sqldata)
    consql.commit()
    data  = cursql.fetchall()
    cursql.close()
  except mdb.IntegrityError as e:
    syslog_trace("DB error : {0}".format(e.__str__), syslog.LOG_ERR,  DEBUG)
    if cursql:
      cursql.close()
      syslog_trace(" *** Closed MySQL connection in do_writesample() ***", syslog.LOG_ERR, DEBUG)
      syslog_trace(" Execution of MySQL command {0} FAILED!".format(sqlcmd), syslog.LOG_INFO, DEBUG)
    pass

  for i, j, k, l in (data):
    if len(xdata) > 0:
      previ = xdata[-1]  # timestamp of last element in list
    else:
      previ = 0          # empty list
    i = mpl.dates.date2num(i)
    if i > previ:
      xdata = np.append(xdata, i)
      ydata = np.append(ydata, [[float(j), float(k), float(l)]], axis=0)

  while len(xdata) > (25 * 3600 / divider):
    xdata = xdata[1:]
  while len(ydata) > len(xdata):
    ydata = ydata[1:]

  return xdata, ydata

@timeme
def update_week_query(consql, xdata, ydata, querydays):
  """Query the database and update the data for the past week"""
  syslog_trace("* Get update of {0} samples for past week".format(querydays), False, DEBUG)
  divider = 14400
  sqlcmd = ("SELECT MIN(sample_time), MIN(temperature), AVG(temperature), MAX(temperature) "
            "FROM systemp "
            "WHERE (sample_time >= NOW() - INTERVAL %s DAY) AND (host = %s) "
            "GROUP BY (sample_epoch DIV %s);")
  sqldata = (querydays, NODE, divider)
  try:
    cursql  = consql.cursor()               # get a cursor on the dB.
    cursql.execute(sqlcmd, sqldata)
    consql.commit()
    data  = cursql.fetchall()
    cursql.close()
  except mdb.IntegrityError as e:
    syslog_trace("DB error : {0}".format(e.__str__), syslog.LOG_ERR,  DEBUG)
    if cursql:
      cursql.close()
      syslog_trace(" *** Closed MySQL connection in do_writesample() ***", syslog.LOG_ERR, DEBUG)
      syslog_trace(" Execution of MySQL command {0} FAILED!".format(sqlcmd), syslog.LOG_INFO, DEBUG)
    pass

  for i, j, k, l in (data):
    if len(xdata) > 0:
      previ = xdata[-1]  # timestamp of last element in list
    else:
      previ = 0          # empty list
    i = mpl.dates.date2num(i)
    if i > previ:
      xdata = np.append(xdata, i)
      ydata = np.append(ydata, [[float(j), float(k), float(l)]], axis=0)

  while len(xdata) > (8 * 86400 / divider):
    xdata = xdata[1:]
  while len(ydata) > len(xdata):
    ydata = ydata[1:]

  return xdata, ydata

@timeme
def update_year_query(consql, xdata, ydata):
  """Query the database and update the data for the past year"""
  syslog_trace("* Get update for past year", False, DEBUG)
  sqlcmd = ("SELECT MIN(sample_time), MIN(temperature), AVG(temperature), MAX(temperature) "
            "FROM systemp "
            "WHERE (sample_time >= NOW() - INTERVAL %s DAY) AND (host = %s) "
            "GROUP BY YEAR(sample_time), MONTH(sample_time), DAY(sample_time);")
  sqldata = (370, NODE)
  try:
    cursql  = consql.cursor()               # get a cursor on the dB.
    cursql.execute(sqlcmd, sqldata)
    consql.commit()
    data  = cursql.fetchall()
    cursql.close()
  except mdb.IntegrityError as e:
    syslog_trace("DB error : {0}".format(e.__str__), syslog.LOG_ERR,  DEBUG)
    if cursql:
      cursql.close()
      syslog_trace(" *** Closed MySQL connection in do_writesample() ***", syslog.LOG_ERR, DEBUG)
      syslog_trace(" Execution of MySQL command {0} FAILED!".format(sqlcmd), syslog.LOG_INFO, DEBUG)
    pass

  for i, j, k, l in (data):
    if len(xdata) > 0:
      previ = xdata[-1]  # timestamp of last element in list
    else:
      previ = 0          # empty list
    i = mpl.dates.date2num(i)
    if i > previ:
      xdata = np.append(xdata, i)
      ydata = np.append(ydata, [[float(j), float(k), float(l)]], axis=0)

  while len(xdata) > 370:
    xdata = xdata[1:]
  while len(ydata) > len(xdata):
    ydata = ydata[1:]

  return xdata, ydata

@timeme
def update_hour_graph(ymin, ymax):
  """(Re)draw the axes of the hour graph"""
  global AX4
  syslog_trace("* (Re)draw graph for past hour", False, DEBUG)
  tenminutes = (1. / 6. / 24.)
  plt.suptitle(PLOT_TITLE + ' ( ' + datetime.datetime.now().strftime("%Y-%m-%dT%H:%M:%S") + ' )')
  major_ticks = np.arange(np.ceil(hourly_data_x[1]/tenminutes)*tenminutes, hourly_data_x[-1], tenminutes)
  AX4.set_ylim([ymin, ymax])
  AX4.set_yticklabels([])
  AX4.set_xlim([hourly_data_x[1], hourly_data_x[-1]])
  AX4.set_xticklabels(hourly_data_x, size='small')
  AX4.set_xticks(major_ticks)
  AX4.xaxis.set_major_formatter(mpl.dates.DateFormatter('%R'))
  AX4.grid(which='major', alpha=0.5)
  AX4.xaxis.set_minor_locator(LOCATEDMINUTES)
  AX4.grid(which='minor', alpha=0.2)

  AX4.plot(hourly_data_x, hourly_data_y, marker='.', linestyle='', color='red', lw=2)

@timeme
def update_day_graph(ymin, ymax):
  """(Re)draw the axes of the day graph"""
  syslog_trace("* (Re)draw graph for past day", False, DEBUG)
  fourhours  = (4. / 24.)
  major_ticks = np.arange(np.ceil(daily_data_x[1]/fourhours)*fourhours, daily_data_x[-1], fourhours)
  AX3.set_ylim([ymin, ymax])
  AX3.set_yticklabels([])
  AX3.set_xlim([daily_data_x[1], daily_data_x[-1]])
  AX3.set_xticklabels(daily_data_x, size='small')
  AX3.set_xticks(major_ticks)
  AX3.xaxis.set_major_formatter(mpl.dates.DateFormatter('%R'))
  AX3.grid(which='major', alpha=0.5)
  AX3.xaxis.set_minor_locator(LOCATEDHOURS)
  AX3.grid(which='minor', alpha=0.2)

  AX3.plot(daily_data_x, daily_data_y[:, 1], marker='.', linestyle='', color='red', lw=2)
  AX3.fill_between(daily_data_x, daily_data_y[:, 0], daily_data_y[:, 2], interpolate=True, color='red', alpha=0.2)

@timeme
def update_week_graph(ymin, ymax):
  """(Re)draw the axes of the week graph"""
  syslog_trace("* (Re)draw graph for past week", False, DEBUG)
  fourhours  = (4. / 24.)
  minor_ticks = np.arange(np.ceil(weekly_data_x[1]/fourhours)*fourhours, weekly_data_x[-1], fourhours)
  AX2.set_ylim([ymin, ymax])
  AX2.set_xlim([weekly_data_x[1], weekly_data_x[-1]])
  AX2.set_xticklabels(weekly_data_x, size='small')
  AX2.xaxis.set_major_locator(LOCATEDDAYS)
  AX2.xaxis.set_major_formatter(mpl.dates.DateFormatter('%a %d'))
  AX2.grid(which='major', alpha=0.5)
  AX2.set_xticks(minor_ticks, minor=True)
  AX2.grid(which='minor', alpha=0.2)

  AX2.plot(weekly_data_x, weekly_data_y[:, 1], linestyle='-', color='red', lw=2)
  AX2.fill_between(weekly_data_x, weekly_data_y[:, 0], weekly_data_y[:, 2], interpolate=True, color='red', alpha=0.2)

@timeme
def update_year_graph(ymin, ymax):
  """(Re)draw the axes of the year graph"""
  syslog_trace("* (Re)draw graph for past year", False, DEBUG)
  # AX1 has no no ylim, we use autoscaling
  AX1.set_xlim([yearly_data_x[1], yearly_data_x[-1]])
  AX1.set_xticklabels(yearly_data_x, size='small')
  AX1.xaxis.set_major_locator(LOCATEDMONTHS)
  AX1.xaxis.set_major_formatter(mpl.dates.DateFormatter('%b %Y'))
  AX1.grid(which='major', alpha=0.5)
  AX1.xaxis.set_minor_locator(LOCATEDMONDAYS)
  AX1.grid(which='minor', alpha=0.2)

  AX1.plot(yearly_data_x, yearly_data_y[:, 1], color='red', lw=1, label='Temperature [degC]')
  AX1.legend(loc='upper left', fontsize='x-small')
  AX1.fill_between(yearly_data_x, yearly_data_y[:, 0], yearly_data_y[:, 2], interpolate=True, color='red', alpha=0.2)

@timeme
def do_main(flock, nu, consql):
  """Main loop: Calls the various subroutines when needed."""
  global hourly_data_x, hourly_data_y
  global daily_data_x, daily_data_y
  global weekly_data_x, weekly_data_y
  global yearly_data_x, yearly_data_y

  syslog_trace("* Lock", False, DEBUG)
  lock(flock)
  currentminute = int(time.strftime('%M'))
  currenthour   = int(time.strftime('%H'))

  # YEAR data
  # data of the last year is updated at 01:11
  if (currenthour == 1) and (currentminute == 11) or nu:
    syslog_trace("* Get new data for year", False, DEBUG)
    syslog_trace("* hour:  {0}".format(currenthour), False, DEBUG)
    if nu:
      yearly_data_x = np.array([])
      yearly_data_y = np.array([[0, 0, 0]])  # initialise array with dummy data
      yearly_data_x, yearly_data_y = update_year_query(consql, yearly_data_x, yearly_data_y)
    else:
      yearly_data_x, yearly_data_y = update_year_query(consql, yearly_data_x, yearly_data_y)
    # print(yearly_data_x)
    # print(yearly_data_y)
    print(len(yearly_data_x), len(yearly_data_y))

  # WEEK data
  # data of the last week is updated every 4 hours
  if (currenthour % 4) == 0 and (currentminute == 1) or nu:
    syslog_trace("* Get new data for week", False, DEBUG)
    syslog_trace("* hour:  {0}".format(currenthour), False, DEBUG)
    if nu:
      weekly_data_x = np.array([])
      weekly_data_y = np.array([[0, 0, 0]])  # initialise array with dummy data
      weekly_data_x, weekly_data_y = update_week_query(consql, weekly_data_x, weekly_data_y, 8)
    else:
      weekly_data_x, weekly_data_y = update_week_query(consql, weekly_data_x, weekly_data_y, 2)
    # print(weekly_data_x)
    # print(weekly_data_y)
    print(len(weekly_data_x), len(weekly_data_y))

  # DAY data
  # data of the last day is updated every 30 minutes
  if (currentminute % 30) == 0 or nu:
    syslog_trace("* Get new data for day", False, DEBUG)
    syslog_trace("* min :  {0}".format(currentminute), False, DEBUG)
    if nu:
      daily_data_x = np.array([])
      daily_data_y = np.array([[0, 0, 0]])  # initialise array with dummy data
      daily_data_x, daily_data_y = update_day_query(consql, daily_data_x, daily_data_y, 25)
    else:
      daily_data_x, daily_data_y = update_day_query(consql, daily_data_x, daily_data_y, 2)
    # print(daily_data_x)
    # print(daily_data_y)
    print(len(daily_data_x), len(daily_data_y))

  # HOUR data
  # data of last hour is updated every minute
  if nu:
    hourly_data_x = np.array([])
    hourly_data_y = np.array([])
    hourly_data_x, hourly_data_y = update_hour_query(consql, hourly_data_x, hourly_data_y, 70)
  else:
    hourly_data_x, hourly_data_y = update_hour_query(consql, hourly_data_x, hourly_data_y, 2)
  print(len(hourly_data_x), len(hourly_data_y))

  # Data post/pre-procesing
  minimum_y = min(np.nanmin(weekly_data_y[:, 0], 0), np.nanmin(daily_data_y[:, 0], 0), np.nanmin(hourly_data_y, 0)) - 1
  maximum_y = max(np.nanmax(weekly_data_y[:, 2], 0), np.nanmax(daily_data_y[:, 2], 0), np.nanmax(hourly_data_y, 0)) + 1

  # YEAR graph
  # graph of the last year is updated at 01:11
  if (currenthour == 1) and (currentminute == 11) or nu:
    update_year_graph(minimum_y, maximum_y)

  # WEEK data
  # graph of the last week is updated every 4 hours
  if (currenthour % 4) == 0 and (currentminute == 1) or nu:
    update_week_graph(minimum_y, maximum_y)

  # DAY data
  # graph of the last day is updated every 30 minutes
  if (currentminute % 30) == 0 or nu:
    update_day_graph(minimum_y, maximum_y)

  # HOUR graph
  # graph of last hour is updated every minute
  update_hour_graph(minimum_y, maximum_y)

  plt.savefig('/tmp/lnxdiagd/site/img/day21.png', format='png')
  syslog_trace("* Unlock", False, DEBUG)
  unlock(flock)
  syslog_trace("* Main Loop end", False, DEBUG)

@timeme
def init_axes():
  """Initialise the figure and its axes."""
  global FIG
  global AX1
  global AX2
  global AX3
  global AX4

  LMARG = 0.056
  # LMPOS = 0.403
  # MRPOS = 0.75
  RMARG = 0.96
  plt.figure(0)
  FIG = plt.gcf()
  DPI = FIG.get_dpi()
  FIG.set_size_inches(1280.0/float(DPI), 640.0/float(DPI))

  # configure the figure
  plt.subplots_adjust(left=LMARG, bottom=None, right=RMARG, top=None,  wspace=0.01, hspace=None)
  plt.suptitle(PLOT_TITLE + ' ( ' + datetime.datetime.now().strftime("%Y-%m-%dT%H:%M:%S") + ' )')

  # figure contains three axes:
  # two rows by three columns
  # top row: YEAR                 full width
  # btm row: WEEK - DAY - HOUR    each 1/3rd of the width
  AX1 = plt.subplot2grid((2, 3), (0, 0), colspan=3)
  AX2 = plt.subplot2grid((2, 3), (1, 0))
  AX3 = plt.subplot2grid((2, 3), (1, 1))
  AX4 = plt.subplot2grid((2, 3), (1, 2))

  # #######################
  # AX1 = [YEAR]
  AX1.set_ylabel(PLOT_Y1LABEL)
  AX1.set_xlabel('past year')
  AX1.grid(True)
  # AX1.xaxis.set_major_locator(LOCATEDMONTHS)
  # AX1.xaxis.set_major_formatter(mpl.dates.DateFormatter('%b %Y'))
  # AX1.grid(which='major', alpha=0.5)
  # AX1.xaxis.set_minor_locator(LOCATEDMONDAYS)
  # AX1.grid(which='minor', alpha=0.2)
  # AX1.legend(loc='upper left', fontsize='x-small')

  # #######################
  # AX2 = [WEEK]
  AX2.set_ylabel(PLOT_Y1LABEL)
  AX2.set_xlabel('past week')
  AX2.grid(True)
  # AX2.xaxis.set_major_locator(LOCATEDDAYS)
  # AX2.xaxis.set_major_formatter(mpl.dates.DateFormatter('%a %d'))
  # AX2.grid(which='major', alpha=0.5)
  # AX2.grid(which='minor', alpha=0.2)

  # #######################
  # AX3 = [DAY]
  AX3.set_xlabel('past day')
  AX3.set_yticklabels([])
  AX3.grid(True)
  # AX3.xaxis.set_major_formatter(mpl.dates.DateFormatter('%R'))
  # AX3.grid(which='major', alpha=0.5)
  # AX3.xaxis.set_minor_locator(LOCATEDHOURS)
  # AX3.grid(which='minor', alpha=0.2)

  # #######################
  # AX4 = [HOUR]
  AX4.set_xlabel('past hour')
  AX4.set_yticklabels([])
  AX4.grid(True)
  # AX4.xaxis.set_major_formatter(mpl.dates.DateFormatter('%R'))
  # AX4.grid(which='major', alpha=0.5)
  # AX4.xaxis.set_minor_locator(LOCATEDMINUTES)
  # AX4.grid(which='minor', alpha=0.2)

def lock(fname):
  """Create a lockfile."""
  open(fname, 'a').close()

def unlock(fname):
  """Remove the lockfile."""
  if os.path.isfile(fname):
    os.remove(fname)

def syslog_trace(trace, logerr, out2console):
  """Log a python stack trace to syslog."""
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
