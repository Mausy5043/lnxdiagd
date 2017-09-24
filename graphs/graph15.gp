#!/usr/bin/env gnuplot

# graph of system log

# datafiles
ifnameh = "/tmp/lnxdiagd/mysql4gnuplot/sql15h.csv"
ifnamed = "/tmp/lnxdiagd/mysql4gnuplot/sql15d.csv"
ifnamew = "/tmp/lnxdiagd/mysql4gnuplot/sql15w.csv"
ifnamey = "/tmp/lnxdiagd/mysql4gnuplot/sql15y.csv"
set output "/tmp/lnxdiagd/site/img/day15.png"

# ******************************************************* General settings *****
set terminal png truecolor enhanced font "Vera,9" size 1280,480
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
TTPOS = 0.95
TBPOS = 0.55
BTPOS = 0.48
BBPOS = 0.08

# ************************************************************* Functions ******
# determine delta data
#delta(x) = ( xD = x - old_x, old_x = x, xD <= 0 ? 0.1 : xD)
#old_x = NaN

nonull(x) = (x <=0 ? 0.1 : x)
min(x,y) = (x < y) ? x : y
max(x,y) = (x > y) ? x : y

# ********************************************************* Statistics (R) *****
# stats to be calculated here of column 2 (UX-epoch)
stats ifnameh using 1 name "X" nooutput
Xh_min = X_min + utc_offset - epoch_compensate
Xh_max = X_max + utc_offset - epoch_compensate

# ********************************************************* Statistics (M) *****
# stats to be calculated here of column 2 (UX-epoch)
stats ifnamed using 1 name "X" nooutput
Xd_min = X_min + utc_offset - epoch_compensate
Xd_max = X_max + utc_offset - epoch_compensate

# ********************************************************* Statistics (L) *****
# stats to be calculated here of column 2 (UX-epoch)
stats ifnamew using 1 name "X" nooutput
Xw_min = X_min + utc_offset - epoch_compensate
Xw_max = X_max + utc_offset - epoch_compensate

# ********************************************************* Statistics (Y) *****
# stats to be calculated here of column 2 (UX-epoch)
stats ifnamey using 1 name "X" nooutput
Xy_min = X_min + utc_offset - epoch_compensate
Xy_max = X_max + utc_offset - epoch_compensate

# ****************************************************************** Title *****
set multiplot layout 2, 3 title "System Logging Linecounts ".strftime("( %Y-%m-%dT%H:%M:%S )", time(0) + utc_offset)
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
#                                                                  UPPER ROW
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
set tmargin at screen TTPOS
set bmargin at screen TBPOS
set lmargin at screen LMARG
set rmargin at screen RMARG

# ***************************************************************** X-axis *****
unset xlabel                 # X-axis label
set xdata time               # Data on X-axis should be interpreted as time
set timefmt "%s"             # Time in log-file is given in Unix format
set format x "%b"            # Display time in 24 hour notation on the X axis
set xrange [ Xy_min : Xy_max ]

# ***************************************************************** Y-axis *****
set ylabel "Count [#]"
set format y "%4.0s%c"
set logscale y 10
set yrange [ 0.1 : ]

# ***************************************************************** Legend *****
set key opaque box inside top left
set key samplen 0.1
set key reverse horizontal Left
set key maxcols 6

# ***************************************************************** Output *****
# ***** PLOT *****
set style data boxes
set style fill solid noborder

plot ifnamey \
      using ($1+utc_offset):(nonull($2+$3+$4+$5+$6+$7)) title "p5" fc "green"  \
  ,'' using ($1+utc_offset):(nonull($2+$3+$4+$5+$6))    title "p4" fc "cyan"   \
  ,'' using ($1+utc_offset):(nonull($2+$3+$4+$5))       title "p3" fc "blue"   \
  ,'' using ($1+utc_offset):(nonull($2+$3+$4))          title "p2" fc "orange" \
  ,'' using ($1+utc_offset):(nonull($2+$3))             title "p1" fc "red"    \
  ,'' using ($1+utc_offset):(nonull($2))                title "p0" fc "black"

# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
#                                                       LEFT PLOT: past week
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


# ***************************************************************** X-axis *****
set xlabel "past week"       # X-axis label
set xdata time               # Data on X-axis should be interpreted as time
set timefmt "%s"             # Time in log-file is given in Unix format
set format x "%a %d"            # Display time in 24 hour notation on the X axis
set xrange [ Xw_min : Xw_max ]

# ***************************************************************** Y-axis *****
set ylabel "Count [#]"
set format y "%4.0s%c"
set logscale y 10
set yrange [ 0.5 : 1000 ]

# ***************************************************************** Legend *****
unset key
#set key opaque box inside top left
#set key samplen 0.1
#set key reverse horizontal Left
#set key maxcols 6

# ***************************************************************** Output *****
# set arrow from graph 0,graph 0 to graph 0,graph 1 nohead lc rgb "red" front
# set arrow from graph 1,graph 0 to graph 1,graph 1 nohead lc rgb "green" front
#set object 1 rect from screen 0,0 to screen 1,1 behind
#set object 1 rect fc rgb "#eeeeee" fillstyle solid 1.0 noborder
#set object 2 rect from graph 0,0 to graph 1,1 behind
#set object 2 rect fc rgb "#ffffff" fillstyle solid 1.0 noborder

set tmargin at screen BTPOS
set bmargin at screen BBPOS
set lmargin at screen LMARG
set rmargin at screen LMPOS

# ***** PLOT *****
set style data boxes
set style fill solid noborder

plot ifnamew \
      using ($1+utc_offset):(nonull($2+$3+$4+$5+$6+$7)) title "p5" fc "green"  \
  ,'' using ($1+utc_offset):(nonull($2+$3+$4+$5+$6))    title "p4" fc "cyan"   \
  ,'' using ($1+utc_offset):(nonull($2+$3+$4+$5))       title "p3" fc "blue"   \
  ,'' using ($1+utc_offset):(nonull($2+$3+$4))          title "p2" fc "orange" \
  ,'' using ($1+utc_offset):(nonull($2+$3))             title "p1" fc "red"    \
  ,'' using ($1+utc_offset):(nonull($2))                title "p0" fc "black"


# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
#                                                     MIDDLE PLOT:  past day
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

# ***************************************************************** X-axis *****
set xlabel "past day"       # X-axis label
set xdata time               # Data on X-axis should be interpreted as time
set timefmt "%s"             # Time in log-file is given in Unix format
set format x "%R"            # Display time in 24 hour notation on the X axis
set xrange [ Xd_min : Xd_max ]

# ***************************************************************** Y-axis *****
set ylabel " "
set ytics format " "
set logscale y 10
set yrange [ 0.5 : 1000 ]

# ***************************************************************** Legend *****
unset key

# ***************************************************************** Output *****
set lmargin at screen LMPOS+0.001
set rmargin at screen MRPOS

# ***** PLOT *****
plot ifnamed \
      using ($1+utc_offset):(nonull($2+$3+$4+$5+$6+$7)) fc "green"  \
  ,'' using ($1+utc_offset):(nonull($2+$3+$4+$5+$6))    fc "cyan"   \
  ,'' using ($1+utc_offset):(nonull($2+$3+$4+$5))       fc "blue"   \
  ,'' using ($1+utc_offset):(nonull($2+$3+$4))          fc "orange" \
  ,'' using ($1+utc_offset):(nonull($2+$3))             fc "red"    \
  ,'' using ($1+utc_offset):(nonull($2))                fc "black"

# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
#                                                      RIGHT PLOT: past hour
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

# ***************************************************************** X-axis *****
set xlabel "past hour"       # X-axis label
set xdata time               # Data on X-axis should be interpreted as time
set timefmt "%s"             # Time in log-file is given in Unix format
set format x "%R"            # Display time in 24 hour notation on the X axis
set xrange [ Xh_min : Xh_max ]
set xtics textcolor rgb "red"

# ***************************************************************** Y-axis *****
set ylabel " "
set ytics format " "
set logscale y 10
set yrange [ 0.5 : 1000 ]

# ***************************************************************** Legend *****
unset key

# ***************************************************************** Output *****
set lmargin at screen MRPOS+0.001
set rmargin at screen RMARG

# ***** PLOT *****
plot ifnameh \
      using ($1+utc_offset):(nonull($2+$3+$4+$5+$6+$7)) fc "green"  \
  ,'' using ($1+utc_offset):(nonull($2+$3+$4+$5+$6))    fc "cyan"   \
  ,'' using ($1+utc_offset):(nonull($2+$3+$4+$5))       fc "blue"   \
  ,'' using ($1+utc_offset):(nonull($2+$3+$4))          fc "orange" \
  ,'' using ($1+utc_offset):(nonull($2+$3))             fc "red"    \
  ,'' using ($1+utc_offset):(nonull($2))                fc "black"

# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
#                                                                 FINALIZING
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

unset multiplot
