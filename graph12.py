#!/usr/bin/env python3

# Graphing load data

import matplotlib as mpl
mpl.use("Agg")                              # activate Anti-Grain Geometry library

import matplotlib.pyplot as plt             # noqa
import numpy as np                          # noqa

# following import is for debugging and profiling
import datetime                             # noqa

def bytespdate2num(fmt, encoding='utf-8'):
  # convert datestring to proper format for numpy.loadtext()
  strconverter = mpl.dates.strpdate2num(fmt)

  def bytesconverter(b):
      s = b.decode(encoding)
      return strconverter(s)
  return bytesconverter

def makegraph12():
  LMARG = 0.056
  # LMPOS = 0.403
  # MRPOS = 0.75
  RMARG = 0.96
  datapath = '/tmp/lnxdiagd/mysql4python'
  hrdata   = 'sql12h.csv'
  dydata   = 'sql12d.csv'
  wkdata   = 'sql12w.csv'
  yrdata   = 'sql12y.csv'
  HR = np.loadtxt(datapath + '/' + hrdata, delimiter=';', converters={0: bytespdate2num("%Y-%m-%d %H:%M:%S")})
  DY = np.loadtxt(datapath + '/' + dydata, delimiter=';', converters={0: bytespdate2num("%Y-%m-%d %H:%M:%S")})
  WK = np.loadtxt(datapath + '/' + wkdata, delimiter=';', converters={0: bytespdate2num("%Y-%m-%d %H:%M:%S")})
  YR = np.loadtxt(datapath + '/' + yrdata, delimiter=';', converters={0: bytespdate2num("%Y-%m-%d %H:%M:%S")})

  #t1 = np.array(YR[:, 0])
  #t2 = np.array(WK[:, 0])
  #t3 = np.array(DY[:, 0])
  #t4 = np.array(HR[:, 0])

  Ymin = 0
  Ymax = 100

  Y2min = 0
  Y2max = max(np.nanmax(WK[:, 1], 0), np.nanmax(DY[:, 1], 0), np.nanmax(HR[:, 1], 0)) * 1.05

  locatedmondays = mpl.dates.WeekdayLocator(mpl.dates.MONDAY)      # find all mondays
  locatedmonths  = mpl.dates.MonthLocator()                        # find all months
  locateddays    = mpl.dates.DayLocator()                          # find all days
  locatedhours   = mpl.dates.HourLocator()                         # find all hours
  locatedminutes = mpl.dates.MinuteLocator()                       # find all minutes

  fourhours  = (4. / 24.)
  tenminutes = (1. / 6. / 24.)

  # decide if there's enough data for a graph
  # rule-of-thumb is to require more than 30 points available for the day-graph
  if len(DY) > 30:
    plt.figure(0)
    fig = plt.gcf()
    DPI = fig.get_dpi()
    fig.set_size_inches(1280.0/float(DPI), 640.0/float(DPI))

    ax1 = plt.subplot2grid((2, 3), (0, 0), colspan=3)
    ax2 = plt.subplot2grid((2, 3), (1, 0))
    ax3 = plt.subplot2grid((2, 3), (1, 1))
    ax4 = plt.subplot2grid((2, 3), (1, 2))

    plt.subplots_adjust(left=LMARG, bottom=None, right=RMARG, top=None,  wspace=0.01, hspace=None)
    plt.suptitle('CPU Load & Usage ( ' + datetime.datetime.now().strftime("%Y-%m-%dT%H:%M:%S") + ' )')

    # #######################
    # [YEAR]
    ax1.set_ylabel('Usage')
    ax1.set_xlabel('past year')
    ax1.set_xlim([YR[1, 0], YR[-1, 0]])
    #
    t = np.array(YR[:, 0])
    ax1.set_xticklabels(t)
    ax1.xaxis.set_major_locator(locatedmonths)
    ax1.xaxis.set_major_formatter(mpl.dates.DateFormatter('%b %Y'))
    ax1.grid(which='major', alpha=0.5)
    ax1.xaxis.set_minor_locator(locatedmondays)
    ax1.grid(which='minor', alpha=0.2)
    #
    s1 = np.array(YR[:, 2])
    s2 = np.sum([s1, np.array(YR[:, 3])], axis=0)
    s3 = np.sum([s2, np.array(YR[:, 4])], axis=0)
    s4 = np.full_like(s1, 100)
    #
    ax1.bar(t, s4, width=1, linewidth=0, color='green', label='idle')
    ax1.bar(t, s3, width=1, linewidth=0, color='blue', label='waiting')
    ax1.bar(t, s2, width=1, linewidth=0, color='yellow', label='system')
    ax1.bar(t, s1, width=1, linewidth=0, color='red', label='user')
    ar1 = ax1.twinx()
    s = np.array(YR[:, 1])
    ar1.plot(t, s, marker='', linestyle='-', color='black', lw=1)
    ax1.legend(loc='upper left', fontsize='x-small')

    # #######################
    # [WEEK]
    minor_ticks = np.arange(np.ceil(WK[1, 0]/fourhours)*fourhours, WK[-1, 0], fourhours)
    ax2.set_ylabel('Temperature [degC]')
    ax2.set_xlabel('past week')
    ax2.set_ylim([Ymin, Ymax])
    ax2.set_xlim([WK[1, 0], WK[-1, 0]])
    #
    t = np.array(WK[:, 0])
    ax2.set_xticklabels(t, size='small')
    ax2.xaxis.set_major_locator(locateddays)
    ax2.xaxis.set_major_formatter(mpl.dates.DateFormatter('%a %d'))
    ax2.grid(which='major', alpha=0.5)
    ax2.set_xticks(minor_ticks, minor=True)
    ax2.grid(which='minor', alpha=0.2)
    #
    s1 = np.array(WK[:, 2])
    s2 = np.sum([s1, np.array(WK[:, 3])], axis=0)
    s3 = np.sum([s2, np.array(WK[:, 4])], axis=0)
    s4 = np.full_like(s1, 100)
    #
    ax2.bar(t, s4, width=0.15, linewidth=0, color='green', label='idle')
    ax2.bar(t, s3, width=0.155, linewidth=0, color='blue', label='waiting')
    ax2.bar(t, s2, width=0.16, linewidth=0, color='yellow', label='system')
    ax2.bar(t, s1, width=0.166, linewidth=0, color='red', label='user')
    ar2 = ax2.twinx()
    s = np.array(WK[:, 1])
    ar2.set_ylim([Y2min, Y2max])
    ar2.set_yticklabels([])
    ar2.plot(t, s, marker='', linestyle='-', color='black', lw=1)

    # #######################
    # [DAY]
    major_ticks = np.arange(np.ceil(DY[1, 0]/fourhours)*fourhours, DY[-1, 0], fourhours)
    ax3.set_xlabel('past day')
    ax3.grid(True)
    ax3.set_ylim([Ymin, Ymax])
    ax3.set_xlim([DY[1, 0], DY[-1, 0]])
    #
    t = np.array(DY[:, 0])
    ax3.set_xticklabels(t, size='small')
    ax3.set_yticklabels([])
    ax3.set_xticks(major_ticks)
    ax3.xaxis.set_major_formatter(mpl.dates.DateFormatter('%R'))
    ax3.grid(which='major', alpha=0.5)
    ax3.xaxis.set_minor_locator(locatedhours)
    ax3.grid(which='minor', alpha=0.2)
    #
    s1 = np.array(DY[:, 2])
    s2 = np.sum([s1, np.array(DY[:, 3])], axis=0)
    s3 = np.sum([s2, np.array(DY[:, 4])], axis=0)
    s4 = np.full_like(s1, 100)
    #
    ax3.bar(t, s4, width=0.016, linewidth=0, color='green', label='idle')
    ax3.bar(t, s3, width=0.017, linewidth=0, color='blue', label='waiting')
    ax3.bar(t, s2, width=0.018, linewidth=0, color='yellow', label='system')
    ax3.bar(t, s1, width=0.019, linewidth=0, color='red', label='user')
    ar3 = ax3.twinx()
    ar3.set_ylim([Y2min, Y2max])
    ar3.set_yticklabels([])
    s = np.array(DY[:, 1])
    ar3.plot(t, s, marker='', linestyle='-', color='black', lw=1)

    # #######################
    # AX4 [HOUR]
    major_ticks = np.arange(np.ceil(HR[1, 0]/tenminutes)*tenminutes, HR[-1, 0], tenminutes)
    ax4.set_xlabel('past hour')
    # ax4.grid(which='minor', alpha=0.2)
    ax4.grid(which='major', alpha=0.5)
    ax4.set_ylim([Ymin, Ymax])
    ax4.set_xlim([HR[1, 0], HR[-1, 0]])
    #
    t = np.array(HR[:, 0])
    ax4.set_xticklabels(t, size='small')
    ax4.set_yticklabels([])
    ax4.set_xticks(major_ticks)
    ax4.xaxis.set_major_formatter(mpl.dates.DateFormatter('%R'))
    ax4.grid(which='major', alpha=0.5)
    ax4.xaxis.set_minor_locator(locatedminutes)
    ax4.grid(which='minor', alpha=0.2)
    #
    s1 = np.array(HR[:, 2])
    s2 = np.sum([s1, np.array(HR[:, 3])], axis=0)
    s3 = np.sum([s2, np.array(HR[:, 4])], axis=0)
    s4 = np.full_like(s1, 100)
    #
    ax4.bar(t, s4, width=0.003, linewidth=0, color='green', label='idle')
    ax4.bar(t, s3, width=0.003, linewidth=0, color='blue', label='waiting')
    ax4.bar(t, s2, width=0.003, linewidth=0, color='yellow', label='system')
    ax4.bar(t, s1, width=0.003, linewidth=0, color='red', label='user')
    ar4 = ax4.twinx()
    ar4.set_ylim([Y2min, Y2max])
    ar4.set_yticklabels([])
    s = np.array(HR[:, 1])
    ar4.plot(t, s, marker='', linestyle='-', color='black', lw=1)

    plt.savefig('/tmp/lnxdiagd/site/img/day12.png', format='png')


if __name__ == "__main__":
  # For debugging and profiling
  startTime = datetime.datetime.now()
  print("")

  makegraph12()

  # For debugging and profiling
  elapsed = datetime.datetime.now() - startTime
  print(" Graphing completed in {0}").format(elapsed)
  print("")

  # Anatomy of a graph:
  #
  #                TITLE
  # +-------------------------------------+
  # |                                     | Y2-axis
  # |               YR                    |
  # |                                     |
  # +-------------------------------------+
  #                 MM
  # +-------------+-----------+-----------+
  # |             |           |           | Y2-axis
  # |      WK     |    DY     |    HR     |
  # |             |           |           |
  # +-------------+-----------+-----------+
  #      Wdy dd       hr:00       hh:mm
  # ^             ^           ^           ^
  # LMARG         LMPOS       MRPOS       RMARG
  # spacing:      (+0.001)    (+0.001)
  # Positions of split between graphs
  # LMARG = 0.056
  # LMPOS = 0.403
  # MRPOS = 0.75
  # RMARG = 0.96
