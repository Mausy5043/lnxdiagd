#!/usr/bin/env python2.7

# daemon8d.py creates an MD-file.

import ConfigParser
import os
import platform
import subprocess
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
    flock           = iniconf.get(inisection, "lockfile")
    fdata           = iniconf.get(inisection, "resultfile")

    # samples         = samplesperCycle * cycles          # total number of samples averaged
    sampleTime      = reportTime/samplesperCycle        # time [s] between samples
    # cycleTime       = samples * sampleTime              # time [s] per cycle

    # mount_path      = '/mnt/share1/'
    # remote_path     = mount_path + NODE
    # remote_lock     = remote_path + '/client.lock'

    try:
      hwdevice      = iniconf.get("11", NODE+".hwdevice")
    except ConfigParser.NoOptionError as e:  # no hwdevice
      hwdevice      = "nohwdevice"
      pass

    while True:
      try:
        startTime   = time.time()

        do_xml(flock, fdata, hwdevice)

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

def do_xml(flock, fdata, hwdevice):
  home              = os.path.expanduser('~')
  uname             = os.uname()
  Tcpu              = "(no T-sensor)"
  fcpu              = "(no f-sensor)"
  # FIXME: read HW paths from .ini
  if os.path.isfile(hwdevice):
    fi = hwdevice
    with open(fi, 'r') as f:
      Tcpu          = float(f.read().strip('\n'))/1000

  if os.path.isfile('/sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq'):
    fi = "/sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq"
    with open(fi, 'r') as f:
      fcpu            = float(f.read().strip('\n'))/1000

  fi = home + "/.lnxdiagd.branch"
  with open(fi, 'r') as f:
    lnxdiagdbranch  = f.read().strip('\n')

  uptime            = subprocess.Popen(["uptime"],      stdout=subprocess.PIPE).stdout.read()
  dfh               = subprocess.Popen(["df", "-h"],    stdout=subprocess.PIPE).stdout.read()
  freeh             = subprocess.Popen(["free", "-h"],  stdout=subprocess.PIPE).stdout.read()
  p1                = subprocess.Popen(["ps", "-e", "-o", "pcpu,args"],           stdout=subprocess.PIPE)
  p2                = subprocess.Popen(["cut", "-c", "-132"],   stdin=p1.stdout,  stdout=subprocess.PIPE)
  p3                = subprocess.Popen(["awk", "NR>2"],         stdin=p2.stdout,  stdout=subprocess.PIPE)
  p4                = subprocess.Popen(["sort", "-nr"],         stdin=p3.stdout,  stdout=subprocess.PIPE)
  p5                = subprocess.Popen(["head", "-10"],         stdin=p4.stdout,  stdout=subprocess.PIPE)
  p6                = subprocess.Popen(["sed", "s/&/\&amp;/g"], stdin=p5.stdout,  stdout=subprocess.PIPE)
  p7                = subprocess.Popen(["sed", "s/>/\&gt;/g"],  stdin=p6.stdout,  stdout=subprocess.PIPE)
  p8                = subprocess.Popen(["sed", "s/</\&lt;/g"],  stdin=p7.stdout,  stdout=subprocess.PIPE)
  psout             = p8.stdout.read()

  lock(flock)

  with open(fdata, 'w') as f:
    f.write(NODE + '\n')

    f.write('\n')
    f.write(dfh + '\n')

    f.write('\n')
    f.write(str(Tcpu) + ' degC @ ' + str(fcpu) + ' MHz\n')

    f.write('\n')
    f.write(freeh + '\n')

    f.write('\n')
    f.write(uptime + '\n')
    f.write(uname[0] + ' ' + uname[1] + ' ' + uname[2] + ' ' + uname[3] + ' ' + uname[4] + ' ' + platform.platform() + '\n')
    f.write(' - lnxdiagd   on: ' + lnxdiagdbranch + '\n')
    f.write('\nTop 10 processes:\n' + psout + '\n')

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
