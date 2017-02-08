#!/usr/bin/env python3

# Graphing CPU temperature data

import matplotlib as mpl
mpl.use("Agg")                              # activate Anti-Grain Geometry library

import matplotlib.pyplot as plt             # noqa
import numpy as nmp                         # noqa

# following import is for debugging and profiling
import datetime                             # noqa

def bytespdate2num(fmt, encoding='utf-8'):
  # convert datestring to proper format for numpy.loadtext()
  strconverter = mpl.dates.strpdate2num(fmt)

  def bytesconverter(b):
      s = b.decode(encoding)
      return strconverter(s)
  return bytesconverter

def makegraph11():
  LMARG = 0.056
  # LMPOS = 0.403
  # MRPOS = 0.75
  RMARG = 0.96
  datapath = '/tmp/lnxdiagd/mysql4python'
  hrdata   = 'sql11h.csv'
  dydata   = 'sql11d.csv'
  wkdata   = 'sql11w.csv'
  yrdata   = 'sql11y.csv'
  HR = nmp.loadtxt(datapath + '/' + hrdata, delimiter=';', converters={0: bytespdate2num("%Y-%m-%d %H:%M:%S")})
  DY = nmp.loadtxt(datapath + '/' + dydata, delimiter=';', converters={0: bytespdate2num("%Y-%m-%d %H:%M:%S")})
  WK = nmp.loadtxt(datapath + '/' + wkdata, delimiter=';', converters={0: bytespdate2num("%Y-%m-%d %H:%M:%S")})
  YR = nmp.loadtxt(datapath + '/' + yrdata, delimiter=';', converters={0: bytespdate2num("%Y-%m-%d %H:%M:%S")})

  Ymin = min(nmp.nanmin(WK[:, 1], 0), nmp.nanmin(DY[:, 1], 0), nmp.nanmin(HR[:, 1], 0)) - 1
  Ymax = max(nmp.nanmax(WK[:, 1], 0), nmp.nanmax(DY[:, 1], 0), nmp.nanmax(HR[:, 1], 0)) + 1

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
    plt.suptitle('Temperature CPU ( ' + datetime.datetime.now().strftime("%Y-%m-%dT%H:%M:%S") + ' )')

    # #######################
    # [YEAR]
    ax1.set_ylabel('Temperature [degC]')
    ax1.set_xlabel('past year')
    ax1.set_xlim([YR[1, 0], YR[-1, 0]])
    #
    t = nmp.array(YR[:, 0])
    ax1.set_xticklabels(t)
    ax1.xaxis.set_major_locator(locatedmonths)
    ax1.xaxis.set_major_formatter(mpl.dates.DateFormatter('%b %Y'))
    ax1.grid(which='major', alpha=0.5)
    ax1.xaxis.set_minor_locator(locatedmondays)
    ax1.grid(which='minor', alpha=0.2)
    #
    s = nmp.array(YR[:, 2])
    slo = nmp.array(YR[:, 1])
    shi = nmp.array(YR[:, 3])
    #
    line01, = ax1.plot(t, s, color='red', lw=1, label='Temperature [degC]')
    ax1.legend(loc='upper left', fontsize='x-small')
    ax1.fill_between(t, slo, shi, interpolate=True, color='red', alpha=0.2)

    # #######################
    # [WEEK]
    minor_ticks = nmp.arange(nmp.ceil(WK[1, 0]/fourhours)*fourhours, WK[-1, 0], fourhours)
    ax2.set_ylabel('Temperature [degC]')
    ax2.set_xlabel('past week')
    ax2.set_ylim([Ymin, Ymax])
    ax2.set_xlim([WK[1, 0], WK[-1, 0]])
    #
    t = nmp.array(WK[:, 0])
    ax2.set_xticklabels(t, size='small')
    ax2.xaxis.set_major_locator(locateddays)
    ax2.xaxis.set_major_formatter(mpl.dates.DateFormatter('%a %d'))
    ax2.grid(which='major', alpha=0.5)
    ax2.set_xticks(minor_ticks, minor=True)
    ax2.grid(which='minor', alpha=0.2)
    #
    s = nmp.array(WK[:, 2])
    slo = nmp.array(WK[:, 1])
    shi = nmp.array(WK[:, 3])
    #
    line02, = ax2.plot(t, s, linestyle='-', color='red', lw=2)
    ax2.fill_between(t, slo, shi, interpolate=True, color='red', alpha=0.2)

    # #######################
    # [DAY]
    major_ticks = nmp.arange(nmp.ceil(DY[1, 0]/fourhours)*fourhours, DY[-1, 0], fourhours)
    ax3.set_xlabel('past day')
    ax3.grid(True)
    ax3.set_ylim([Ymin, Ymax])
    ax3.set_xlim([DY[1, 0], DY[-1, 0]])
    #
    t = nmp.array(DY[:, 0])
    ax3.set_xticklabels(t, size='small')
    ax3.set_yticklabels([])
    ax3.set_xticks(major_ticks)
    ax3.xaxis.set_major_formatter(mpl.dates.DateFormatter('%R'))
    ax3.grid(which='major', alpha=0.5)
    ax3.xaxis.set_minor_locator(locatedhours)
    ax3.grid(which='minor', alpha=0.2)
    #
    s = nmp.array(DY[:, 2])
    slo = nmp.array(DY[:, 1])
    shi = nmp.array(DY[:, 3])
    line03, = ax3.plot(t, s, marker='.', linestyle='', color='red', lw=2)
    ax3.fill_between(t, slo, shi, interpolate=True, color='red', alpha=0.2)

    # #######################
    # AX4 [HOUR]
    major_ticks = nmp.arange(nmp.ceil(HR[1, 0]/tenminutes)*tenminutes, HR[-1, 0], tenminutes)
    ax4.set_xlabel('past hour')
    # ax4.grid(which='minor', alpha=0.2)
    ax4.grid(which='major', alpha=0.5)
    ax4.set_ylim([Ymin, Ymax])
    ax4.set_xlim([HR[1, 0], HR[-1, 0]])
    #
    t = nmp.array(HR[:, 0])
    ax4.set_xticklabels(t, size='small')
    ax4.set_yticklabels([])
    ax4.set_xticks(major_ticks)
    ax4.xaxis.set_major_formatter(mpl.dates.DateFormatter('%R'))
    ax4.grid(which='major', alpha=0.5)
    ax4.xaxis.set_minor_locator(locatedminutes)
    ax4.grid(which='minor', alpha=0.2)
    #
    s = nmp.array(HR[:, 1])
    line04, = ax4.plot(t, s, marker='.', linestyle='', color='red', lw=2)

    plt.savefig('/tmp/domog/site/img/day11.png', format='png')


if __name__ == "__main__":
  # For debugging and profiling
  startTime = datetime.datetime.now()
  print("")

  makegraph11()

  # For debugging and profiling
  elapsed = datetime.datetime.now() - startTime
  print(" Graphing completed in %s" % (elapsed))
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
