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

from mausy5043libs.libdaemon3 import Daemon
import mausy5043funcs.fileops3 as mf

# constants
DEBUG       = False
IS_JOURNALD = os.path.isfile('/bin/journalctl')
MYID        = "".join(list(filter(str.isdigit, os.path.realpath(__file__).split('/')[-1])))
MYAPP       = os.path.realpath(__file__).split('/')[-3]
NODE        = os.uname()[1]

if (NODE == "boson"):
  from mausy5043libs.libsmart3 import SmartDisk
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
    reporttime      = iniconf.getint(inisection, "reporttime")
    # cycles          = iniconf.getint(inisection, "cycles")
    samplespercycle = iniconf.getint(inisection, "samplespercycle")
    flock           = iniconf.get(inisection, "lockfile")
    fdata           = iniconf.get(inisection, "markdown")

    # samples         = samplespercycle * cycles          # total number of samples averaged
    sampletime      = reporttime/samplespercycle        # time [s] between samples
    # cycleTime       = samples * sampletime              # time [s] per cycle

    try:
      hwdevice      = iniconf.get("11", NODE + ".hwdevice")
    except configparser.NoOptionError:  # no hwdevice
      hwdevice      = "nohwdevice"
      pass

    while True:
      try:
        starttime   = time.time()

        do_markdown(flock, fdata, hwdevice)

        waittime    = sampletime - (time.time() - starttime) - (starttime % sampletime)
        if (waittime > 0):
          mf.syslog_trace("Waiting  : {0}s".format(waittime), False, DEBUG)
          mf.syslog_trace("................................", False, DEBUG)
          time.sleep(waittime)
      except Exception:
        mf.syslog_trace("Unexpected error in run()", syslog.LOG_CRIT, DEBUG)
        mf.syslog_trace(traceback.format_exc(), syslog.LOG_CRIT, DEBUG)
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
  fcpu_stats        = str(subprocess.check_output(["cpufreq-info", "-sm"]), 'utf-8')

  fi = home + "/.lnxdiagd.branch"
  with open(fi, 'r') as f:
    lnxdiagdbranch  = f.read().strip('\n')

  if os.path.isfile("/proc/mdstat"):
    mds               = "-\n" + str(subprocess.check_output(["cat", "/proc/mdstat"]), 'utf-8')
  uptime            = str(subprocess.check_output(["uptime"]), 'utf-8')
  # dfh               = str(subprocess.check_output(["df", "-h"]), 'utf-8')
  # freeh             = str(subprocess.check_output(["free", "-h"]), 'utf-8')
  # p1                = subprocess.Popen(["ps", "-e", "-o", "pcpu,args"],           stdout=subprocess.PIPE, stderr=subprocess.PIPE)
  # p2                = subprocess.Popen(["cut", "-c", "-132"],   stdin=p1.stdout,  stdout=subprocess.PIPE, stderr=subprocess.PIPE)
  # p3                = subprocess.Popen(["awk", "NR>2"],         stdin=p2.stdout,  stdout=subprocess.PIPE, stderr=subprocess.PIPE)
  # p4                = subprocess.Popen(["sort", "-nr"],         stdin=p3.stdout,  stdout=subprocess.PIPE, stderr=subprocess.PIPE)
  # p5                = subprocess.Popen(["head", "-10"],         stdin=p4.stdout,  stdout=subprocess.PIPE, stderr=subprocess.PIPE)
  # ps, err            = p5.communicate()
  # psout             = str(ps, 'utf-8')

  mf.lock(flock)

  with open(fdata, 'w') as f:
    mf.syslog_trace("writing {0}".format(fdata), False, DEBUG)
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
    f.write('!! ' + str(Tcpu) + ' degC @ ' + str(fcpu) + ' MHz    stats: ' + fcpu_stats + '\n\n')
    f.write('### Server Graphs:  \n')
    if (hwdevice != "nohwdevice"):
      f.write('![A GNUplot image should be here: day11.png](img/day11.png)\n')
      # f.write('![A GNUplot image should be here: day11.png](img/day11.old.png)\n')
    f.write('![A GNUplot image should be here: day12.png](img/day12.png)\n')
    f.write('![A GNUplot image should be here: day14.png](img/day14.png)\n')
    f.write('![A GNUplot image should be here: day13.png](img/day13.png)\n')
    f.write('![A GNUplot image should be here: day15.png](img/day15.png)\n')
    if (NODE == "boson"):
      f.write('![A GNUplot image should be here: day19.png](img/day19.png)\n')

    # # Disk usage
    # f.write('## Disk Usage\n')
    # f.write(dfh)      # dfh comes with its own built-in '/n'
    if (NODE == "boson"):
      f.write('```\n')
      f.write(mds)    # mds comes with its own built-in '/n'
      f.write('```\n\n')

    if (NODE == "boson"):
      rbc_sda = sda.getdata('5')
      rbc_sdb = sdb.getdata('5')
      rbc_sdc = sdc.getdata('5')
      rbc_sdd = sdd.getdata('5')
      rbc_sde = sde.getdata('5')
      # ou_sda = sda.getdata('198')
      ou_sdb = sdb.getdata('198')
      ou_sdc = sdc.getdata('198')
      ou_sdd = sdd.getdata('198')
      ou_sde = sde.getdata('198')
      # disktemperature
      temperature_sda = sda.getdata('194')
      temperature_sdb = sdb.getdata('194')
      temperature_sdc = sdc.getdata('194')
      temperature_sdd = sdd.getdata('194')
      temperature_sde = sde.getdata('194')
      # disk power-on time
      pwron_time_a = sda.getdata('9')
      pwron_time_b = sdb.getdata('9')
      pwron_time_c = sdc.getdata('9')
      pwron_time_d = sdd.getdata('9')
      pwron_time_e = sde.getdata('9')
      # disk health
      health_sda = sda.gethealth()
      health_sdb = sdb.gethealth()
      health_sdc = sdc.gethealth()
      health_sdd = sdd.gethealth()
      health_sde = sde.gethealth()
      # Self-test info
      test_sda = sda.getlasttest()   # noqa
      test_sdb = sdb.getlasttest()
      test_sdc = sdc.getlasttest()
      test_sdd = sdd.getlasttest()
      test_sde = sde.getlasttest()
      # Disk info
      info_sda = sda.getinfo()
      info_sdb = sdb.getinfo()
      info_sdc = sdc.getinfo()
      info_sdd = sdd.getinfo()
      info_sde = sde.getinfo()
      f.write('```\n')
      f.write('SSD: ' + temperature_sda + ' || disk1: ' + temperature_sdb + ' || disk2: ' + temperature_sdc + ' || disk3: ' + temperature_sdd + ' || disk4: ' + temperature_sde + ' [degC]\n')
      f.write('\n')
      f.write('---SSD---\n')
      f.write(' Name      : ' + info_sda + '\n')
      f.write(' PowerOn   : ' + pwron_time_a + '\n')
      # f.write(' Last test : ' + test_sda + '\n')
      if "PASSED" not in health_sda:
        f.write('             ' + health_sda + '\n')
      if not(rbc_sda == "0"):
        f.write('              Retired Block Count (5) = ' + rbc_sda + '\n')

      f.write('---disk1---\n')
      f.write(' Name      : ' + info_sdb + '\n')
      f.write(' PowerOn   : ' + pwron_time_b + '\n')
      if "without" not in test_sdb:
        f.write(' Last test : ' + test_sdb + '\n')
      if "PASSED" not in health_sdb:
        f.write('             ' + health_sdb + '\n')
      if not(rbc_sdb == "0") or not(ou_sdb == "0"):
        f.write('              Retired Block Count (5) = ' + rbc_sdb + ' - Offline Uncorrectable (198) = ' + ou_sdb + '\n')

      f.write('---disk2---\n')
      f.write(' Name      : ' + info_sdc + '\n')
      f.write(' PowerOn   : ' + pwron_time_c + '\n')
      if "without" not in test_sdc:
        f.write(' Last test : ' + test_sdc + '\n')
      if "PASSED" not in health_sdc:
        f.write('             ' + health_sdc + '\n')
      if not(rbc_sdc == "0") or not(ou_sdc == "0"):
        f.write('              Retired Block Count (5) = ' + rbc_sdc + ' - Offline Uncorrectable (198) = ' + ou_sdc + '\n')

      f.write('---disk3---\n')
      f.write(' Name      : ' + info_sdd + '\n')
      f.write(' PowerOn   : ' + pwron_time_d + '\n')
      if "without" not in test_sdd:
        f.write(' Last test : ' + test_sdd + '\n')
      if "PASSED" not in health_sdd:
        f.write('             ' + health_sdd + '\n')
      if not(rbc_sdd == "0") or not(ou_sdd == "0"):
        f.write('              Retired Block Count (5) = ' + rbc_sdd + ' - Offline Uncorrectable (198) = ' + ou_sdd + '\n')

      f.write('---disk4---\n')
      f.write(' Name      : ' + info_sde + '\n')
      f.write(' PowerOn   : ' + pwron_time_e + '\n')
      if "without" not in test_sde:
        f.write(' Last test : ' + test_sde + '\n')
      if "PASSED" not in health_sde:
        f.write('             ' + health_sde + '\n')
      if not(rbc_sde == "0") or not(ou_sde == "0"):
        f.write('              Retired Block Count (5) = ' + rbc_sde + ' - Offline Uncorrectable (198) = ' + ou_sde + '\n')
      f.write(' ')
      f.write('```\n\n')

    # # Memory usage
    # f.write('## Memory Usage\n')
    # f.write('```\n')
    # f.write(freeh)    # freeh comes with its own built-in '/n'
    # f.write('```\n\n')

    # # Top 10 processes
    # f.write('## Top 10 processes:\n')
    # f.write('```\n')
    # f.write(psout)    # psout comes with its own built-in '/n'
    # f.write('```\n\n')

  mf.unlock(flock)


if __name__ == "__main__":
  daemon = MyDaemon('/tmp/' + MYAPP + '/' + MYID + '.pid')
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
