#!/usr/bin/env gnuplot

# graph of count of loglines

# datafile
ifname = "/tmp/lnxdiagd/mysql/sql15w.csv"
set output "/tmp/lnxdiagd/site/img/day15.old.png"

# ******************************************************* General settings *****
set terminal png enhanced font "Vera,9" size 1280,320
set datafile separator ';'
set datafile missing "NaN"    # Ignore missing values
set grid front
tz_offset = utc_offset / 3600 # GNUplot only works with UTC. Need to compensate
                              # for timezone ourselves.
if (GPVAL_VERSION == 4.6) {epoch_compensate = 946684800} else {if (GPVAL_VERSION == 5.0) {epoch_compensate = 0}}
# Positions of split between graphs
LMARG = 0.06
LMPOS = 0.40
MRPOS = 0.73
RMARG = 0.94

# ************************************************************* Functions ******
# determine delta data
#delta(x) = ( xD = x - old_x, old_x = x, xD <= 0 ? 0.1 : xD)
#old_x = NaN

nonull(x) = (x <= 0 ? 0.1 : x)

# ************************************************************* Statistics *****
# stats to be calculated here of column 2 (UX-epoch)
stats ifname using 2 name "X" nooutput

X_min = X_min + utc_offset - epoch_compensate
X_max = X_max + utc_offset - epoch_compensate

# ****************************************************************** Title *****
set title "System Logging Linecounts ".strftime("( %Y-%m-%dT%H:%M:%S )", time(0) + utc_offset)

# ***************************************************************** X-axis *****
set xlabel "Date/Time"       # X-axis label
set xdata time               # Data on X-axis should be interpreted as time
set timefmt "%s"             # Time in log-file is given in Unix format
set format x "%a %d"            # Display time in 24 hour notation on the X axis
set xtics rotate by 40 right
set xrange [ X_min : X_max ]

# ***************************************************************** Y-axis *****
set ylabel "Count [#]"
set format y "%4.0s%c"
set logscale y 10
set yrange [ 0.5 : ]

# ***************************************************************** Legend *****
set key opaque box inside top left
set key samplen 0.1
set key reverse horizontal Left

# ***************************************************************** Output *****

# ***** PLOT *****
set lmargin at screen LMARG
set rmargin at screen RMARG

set style data boxes
set style fill solid noborder

plot ifname \
      using ($2+utc_offset):(nonull($4+$5+$6+$7+$8+$9)) title "p5" fc "green"  \
  ,'' using ($2+utc_offset):(nonull($4+$5+$6+$7+$8))    title "p4" fc "cyan"   \
  ,'' using ($2+utc_offset):(nonull($4+$5+$6+$7))       title "p3" fc "blue"   \
  ,'' using ($2+utc_offset):(nonull($4+$5+$6))          title "p2" fc "orange" \
  ,'' using ($2+utc_offset):(nonull($4+$5))             title "p1" fc "red"    \
  ,'' using ($2+utc_offset):(nonull($4))                title "p0" fc "black"