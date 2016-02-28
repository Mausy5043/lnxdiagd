#!/usr/bin/env python

# Library offering common functions

import os, syslog, platform

DEBUG = False
IS_JOURNALD = os.path.isfile('/bin/journalctl')
LEAF = os.path.realpath(__file__).split('/')[-2]
NODE = platform.node()

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
      syslog.syslog(logerr,line)
    if line and out2console:
      print line
