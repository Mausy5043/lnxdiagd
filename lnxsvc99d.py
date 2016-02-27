#!/usr/bin/env python

# Based on previous work by
# Charles Menguy (see: http://stackoverflow.com/questions/10217067/implementing-a-full-python-unix-style-daemon-process)
# and Sander Marechal (see: http://www.jejik.com/articles/2007/02/a_simple_unix_linux_daemon_in_python/)

# Adapted by M.Hendrix [2015]

# daemon99.py creates an XML-file on the server.

import syslog, traceback
import os, sys, platform, time, commands, subprocess
from libdaemon import Daemon
import ConfigParser

DEBUG = False
IS_JOURNALD = os.path.isfile('/bin/journalctl')
leaf = os.path.realpath(__file__).split('/')[-2]

class MyDaemon(Daemon):
  def run(self):
    iniconf = ConfigParser.ConfigParser()
    inisection = "99"
    home = os.path.expanduser('~')
    s = iniconf.read(home + '/' + leaf + '/config.ini')
    if DEBUG: print "config file : ", s
    if DEBUG: print iniconf.items(inisection)
    reportTime = iniconf.getint(inisection, "reporttime")
    cycles = iniconf.getint(inisection, "cycles")
    samplesperCycle = iniconf.getint(inisection, "samplespercycle")
    flock = iniconf.get(inisection, "lockfile")

    samples = samplesperCycle * cycles              # total number of samples averaged
    sampleTime = reportTime/samplesperCycle         # time [s] between samples
    cycleTime = samples * sampleTime                # time [s] per cycle

    myname = os.uname()[1]
    mount_path = '/mnt/share1/'
    remote_path = mount_path + myname
    remote_lock = remote_path + '/client.lock'

    while True:
      try:
        startTime=time.time()

        if os.path.ismount(mount_path):
          # print 'dataspool is mounted'
          do_xml(remote_path)

        waitTime = sampleTime - (time.time() - startTime) - (startTime%sampleTime)
        if (waitTime > 0):
          if DEBUG:print "Waiting {0} s".format(waitTime)
          time.sleep(waitTime)
      except Exception as e:
        if DEBUG:
          print "Unexpected error:"
          print e.message
        syslog.syslog(syslog.LOG_ALERT,e.__doc__)
        syslog_trace(traceback.format_exc())
        raise

def do_xml(wpath):
  home						= os.path.expanduser('~')
  #usr							= commands.getoutput("whoami")
  uname           = os.uname()

  Tcpu = "(no T-sensor)"
  if os.path.isfile('/sys/class/hwmon/hwmon0/device/temp1_input'):
    fi = "/sys/class/hwmon/hwmon0/device/temp1_input"
    with open(fi,'r') as f:
      Tcpu = float(f.read().strip('\n'))/1000


  fi = "/sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq"
  with open(fi,'r') as f:
    fcpu						= float(f.read().strip('\n'))/1000


  fi = home + "/.lnxdiagd.branch"
  with open(fi,'r') as f:
    lnxdiagdbranch = f.read().strip('\n')


  #fi = home + "/.boneboot.branch"
  #with open(fi,'r') as f:
  #  bonebootbranch  = f.read().strip('\n')


  uptime          = commands.getoutput("uptime")
  dfh             = commands.getoutput("df -h")
  freeh           = commands.getoutput("free -h")
  p1              = subprocess.Popen(["ps", "-e", "-o", "pcpu,args"], stdout=subprocess.PIPE)
  p2              = subprocess.Popen(["cut", "-c", "-132"], stdin=p1.stdout, stdout=subprocess.PIPE)
  p3              = subprocess.Popen(["awk", "NR>2"], stdin=p2.stdout, stdout=subprocess.PIPE)
  p4              = subprocess.Popen(["sort", "-nr"], stdin=p3.stdout, stdout=subprocess.PIPE)
  p5              = subprocess.Popen(["head", "-10"], stdin=p4.stdout, stdout=subprocess.PIPE)
  p6              = subprocess.Popen(["sed", "s/&/\&amp;/g"], stdin=p5.stdout, stdout=subprocess.PIPE)
  p7              = subprocess.Popen(["sed", "s/>/\&gt;/g"], stdin=p6.stdout, stdout=subprocess.PIPE)
  p8              = subprocess.Popen(["sed", "s/</\&lt;/g"], stdin=p7.stdout, stdout=subprocess.PIPE)
  psout           = p8.stdout.read()
  #
  with open(wpath + '/status.xml', 'w') as f:

    f.write('<server>\n')

    f.write('<name>\n')
    f.write(uname[1] + '\n')
    f.write('</name>\n')

    f.write('<df>\n')
    f.write(dfh + '\n')
    f.write('</df>\n')

    f.write('<temperature>\n')
    f.write(str(Tcpu) + ' degC @ '+ str(fcpu) +' MHz\n')
    f.write('</temperature>\n')

    f.write('<memusage>\n')
    f.write(freeh + '\n')
    f.write('</memusage>\n')

    f.write(' <uptime>\n')
    f.write(uptime + '\n')
    f.write(uname[0]+ ' ' +uname[1]+ ' ' +uname[2]+ ' ' +uname[3]+ ' ' +uname[4]+ ' ' +platform.platform() +'\n')
    f.write(' - lnxdiagd   on: '+ lnxdiagdbranch +'\n')
    #f.write(' - boneboot    on: '+ bonebootbranch +'\n')
    f.write('\nTop 10 processes:\n' + psout +'\n')
    f.write('</uptime>\n')

    f.write('</server>\n')

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
  daemon = MyDaemon('/tmp/' + leaf + '/99.pid')
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
