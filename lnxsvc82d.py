#!/usr/bin/env python3

# daemon8d.py creates an MD-file.

import configparser
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
MYID        = "".join(list(filter(str.isdigit, os.path.realpath(__file__).split('/')[-1])))
MYAPP       = os.path.realpath(__file__).split('/')[-2]
NODE        = os.uname()[1]

if (NODE == "boson"):
  from libsmart3 import SmartDisk
  # BEWARE
  # The disks identified here as `sda`, `sdb` etc. may not necessarily
  # be called `/dev/sda`, `/dev/sdb` etc. on the system!!
  sda = SmartDisk("wwn-0x50026b723c0d6dd5")  # SSD 50026B723C0D6DD5
  sda.smart()
  sdb = SmartDisk("wwn-0x50014ee261020fce")  # WD-WCC4N5PF96KD
  sdb.smart()
  sdc = SmartDisk("wwn-0x50014ee605a043e2")  # WD-WMC4N0K01249
  sdc.smart()
  sdd = SmartDisk("wwn-0x50014ee6055a237b")  # WD-WMC4N0J6Y6LW
  sdd.smart()
  sde = SmartDisk("wwn-0x50014ee60507b79c")  # WD-WMC4N0E24DVU
  sde.smart()
  # sdf =
  # sdg =

class MyDaemon(Daemon):
  def run(self):
    iniconf         = configparser.ConfigParser()
    inisection      = MYID
    home            = os.path.expanduser('~')
    s               = iniconf.read(home + '/' + MYAPP + '/config.ini')
    syslog_trace("Config file   : {0}".format(s), False, DEBUG)
    syslog_trace("Options       : {0}".format(iniconf.items(inisection)), False, DEBUG)
    reportTime      = iniconf.getint(inisection, "reporttime")
    # cycles          = iniconf.getint(inisection, "cycles")
    samplesperCycle = iniconf.getint(inisection, "samplespercycle")
    flock           = iniconf.get(inisection, "lockfile")
    fdata           = iniconf.get(inisection, "markdown")

    # samples         = samplesperCycle * cycles          # total number of samples averaged
    sampleTime      = reportTime/samplesperCycle        # time [s] between samples
    # cycleTime       = samples * sampleTime              # time [s] per cycle

    try:
      hwdevice      = iniconf.get("11", NODE + ".hwdevice")
    except configparser.NoOptionError:  # no hwdevice
      hwdevice      = "nohwdevice"
      pass

    while True:
      try:
        startTime   = time.time()

        do_markdown(flock, fdata, hwdevice)

        waitTime    = sampleTime - (time.time() - startTime) - (startTime % sampleTime)
        if (waitTime > 0):
          syslog_trace("Waiting  : {0}s".format(waitTime), False, DEBUG)
          syslog_trace("................................", False, DEBUG)
          time.sleep(waitTime)
      except Exception:
        syslog_trace("Unexpected error in run()", syslog.LOG_CRIT, DEBUG)
        syslog_trace(traceback.format_exc(), syslog.LOG_CRIT, DEBUG)
        raise

def do_markdown(flock, fdata, hwdevice):
  home              = os.path.expanduser('~')
  uname             = os.uname()
  Tcpu              = "(no T-sensor)"
  fcpu              = "(no f-sensor)"
  mds               = ""
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

  if os.path.isfile("/proc/mdstat"):
    mds               = "-\n" + str(subprocess.check_output(["cat", "/proc/mdstat"]), 'utf-8')
  uptime            = str(subprocess.check_output(["uptime"]), 'utf-8')
  dfh               = str(subprocess.check_output(["df", "-h"]), 'utf-8')
  freeh             = str(subprocess.check_output(["free", "-h"]), 'utf-8')
  p1                = subprocess.Popen(["ps", "-e", "-o", "pcpu,args"],           stdout=subprocess.PIPE)
  p2                = subprocess.Popen(["cut", "-c", "-132"],   stdin=p1.stdout,  stdout=subprocess.PIPE)
  p3                = subprocess.Popen(["awk", "NR>2"],         stdin=p2.stdout,  stdout=subprocess.PIPE)
  p4                = subprocess.Popen(["sort", "-nr"],         stdin=p3.stdout,  stdout=subprocess.PIPE)
  p5                = subprocess.Popen(["head", "-10"],         stdin=p4.stdout,  stdout=subprocess.PIPE)
  psout             = str(p5.stdout.read(), 'utf-8')

  lock(flock)

  with open(fdata, 'w') as f:
    syslog_trace("writing {0}".format(fdata), False, DEBUG)
    # YAML header
    f.write('---\n')
    f.write('title: ' + NODE + '\n')
    f.write('menu: ' + NODE + '\n')
    f.write('---\n')

    # HEADER
    f.write('# ' + NODE + '\n\n')

    # System ID
    f.write('!!! ')
    f.write(uname[0] + ' ' + uname[2] + ' ' + uname[3] + ' ' + uname[4] + ' ' + platform.platform() + '  \n')

    # lnxdiagd branch
    f.write('!!! lnxdiagd   on: ' + lnxdiagdbranch + '\n\n')

    # System Uptime
    f.write('### Server Uptime:  \n')
    f.write('!!! ')
    f.write(uptime)
    f.write('\n')

    # CPU temperature and frequency
    f.write('### Server Temperature:  \n')
    f.write('!! ' + str(Tcpu) + ' degC @ ' + str(fcpu) + ' MHz\n\n')
    f.write('### Server Graphs:  \n')
    if (hwdevice != "nohwdevice"):
      # f.write('![A GNUplot image should be here: day11.svg](img/day11.svg)\n')
      f.write('![A GNUplot image should be here: day11.png](img/day11.png)\n')
    f.write('![A GNUplot image should be here: day12.png](img/day12.png)\n')
    f.write('![A GNUplot image should be here: day14.png](img/day14.png)\n')
    f.write('![A GNUplot image should be here: day13.png](img/day13.png)\n')
    f.write('![A GNUplot image should be here: day15.png](img/day15.png)\n')
    if (NODE == "boson"):
      f.write('![A GNUplot image should be here: day19.png](img/day19.png)\n')

    # Disk usage
    f.write('## Disk Usage\n')
    f.write('```\n')
    f.write(dfh)      # dfh comes with its own built-in '/n'
    if (NODE == "boson"):
      f.write(mds)    # mds comes with its own built-in '/n'
    f.write('```\n\n')

    if (NODE == "boson"):
      RBCsda = sda.getdata('5')
      RBCsdb = sdb.getdata('5')
      RBCsdc = sdc.getdata('5')
      RBCsdd = sdd.getdata('5')
      RBCsde = sde.getdata('5')
      # OUsda = sda.getdata('198')
      OUsdb = sdb.getdata('198')
      OUsdc = sdc.getdata('198')
      OUsdd = sdd.getdata('198')
      OUsde = sde.getdata('198')
      # disktemperature
      Tsda = sda.getdata('194')
      Tsdb = sdb.getdata('194')
      Tsdc = sdc.getdata('194')
      Tsdd = sdd.getdata('194')
      Tsde = sde.getdata('194')
      # disk power-on time
      Pta = sda.getdata('9')
      Ptb = sdb.getdata('9')
      Ptc = sdc.getdata('9')
      Ptd = sdd.getdata('9')
      Pte = sde.getdata('9')
      # disk health
      Hda = sda.gethealth()
      Hdb = sdb.gethealth()
      Hdc = sdc.gethealth()
      Hdd = sdd.gethealth()
      Hde = sde.gethealth()
      # Self-test info
      Testa = sda.getlasttest()
      Testb = sdb.getlasttest()
      Testc = sdc.getlasttest()
      Testd = sdd.getlasttest()
      Teste = sde.getlasttest()
      # Disk info
      Infoa = sda.getinfo()
      Infob = sdb.getinfo()
      Infoc = sdc.getinfo()
      Infod = sdd.getinfo()
      Infoe = sde.getinfo()
      f.write('```\n')
      f.write('SSD: ' + Tsda + ' || disk1: ' + Tsdb + ' || disk2: ' + Tsdc + ' || disk3: ' + Tsdd + ' || disk4: ' + Tsde + ' [degC]\n')
      f.write('\n')
      f.write('---SSD---\n')
      f.write(' Name      : ' + Infoa + '\n')
      f.write(' PowerOn   : ' + Pta + '\n')
      f.write(' Last test : ' + Testa + '\n')
      if "PASSED" not in Hda:
        f.write('             ' + Hda + '\n')
      if not(RBCsda == "0"):
        f.write('              Retired Block Count (5) = ' + RBCsda + '\n')

      f.write('---disk1---\n')
      f.write(' Name      : ' + Infob + '\n')
      f.write(' PowerOn   : ' + Ptb + '\n')
      # if "without" not in Testb:
      f.write(' Last test : ' + Testb + '\n')
      # if "PASSED" not in Hdb:
        f.write('             ' + Hdb + '\n')
      if not(RBCsdb == "0") or not(OUsdb == "0"):
        f.write('              Retired Block Count (5) = ' + RBCsdb + ' - Offline Uncorrectable (198) = ' + OUsdb + '\n')

      f.write('---disk2---\n')
      f.write(' Name      : ' + Infoc + '\n')
      f.write(' PowerOn   : ' + Ptc + '\n')
      if "without" not in Testc:
        f.write(' Last test : ' + Testc + '\n')
      if "PASSED" not in Hdc:
        f.write('             ' + Hdc + '\n')
      if not(RBCsdc == "0") or not(OUsdc == "0"):
        f.write('              Retired Block Count (5) = ' + RBCsdc + ' - Offline Uncorrectable (198) = ' + OUsdc + '\n')

      f.write('---disk3---\n')
      f.write(' Name      : ' + Infod + '\n')
      f.write(' PowerOn   : ' + Ptd + '\n')
      if "without" not in Testd:
        f.write(' Last test : ' + Testd + '\n')
      if "PASSED" not in Hdd:
        f.write('             ' + Hdd + '\n')
      if not(RBCsdd == "0") or not(OUsdd == "0"):
        f.write('              Retired Block Count (5) = ' + RBCsdd + ' - Offline Uncorrectable (198) = ' + OUsdd + '\n')

      f.write('---disk4---\n')
      f.write(' Name      : ' + Infoe + '\n')
      f.write(' PowerOn   : ' + Pte + '\n')
      if "without" not in Teste:
        f.write(' Last test : ' + Teste + '\n')
      if "PASSED" not in Hde:
        f.write('             ' + Hde + '\n')
      if not(RBCsde == "0") or not(OUsde == "0"):
        f.write('              Retired Block Count (5) = ' + RBCsde + ' - Offline Uncorrectable (198) = ' + OUsde + '\n')
      f.write(' ')
    f.write('```\n\n')

    # Memory usage
    f.write('## Memory Usage\n')
    f.write('```\n')
    f.write(freeh)    # freeh comes with its own built-in '/n'
    f.write('```\n\n')

    # Top 10 processes
    f.write('## Top 10 processes:\n')
    f.write('```\n')
    f.write(psout)    # psout comes with its own built-in '/n'
    f.write('```\n\n')

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
