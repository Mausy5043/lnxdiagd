#!/usr/bin/env gnuplot

# graph of CPU load

# datafiles
ifnameh = "/tmp/lnxdiagd/mysql4gnuplot/sql12h.csv"
ifnamed = "/tmp/lnxdiagd/mysql4gnuplot/sql12d.csv"
ifnamew = "/tmp/lnxdiagd/mysql4gnuplot/sql12w.csv"
ifnamey = "/tmp/lnxdiagd/mysql4gnuplot/sql12y.csv"
set output "/tmp/lnxdiagd/site/img/day12.png"

# ******************************************************* General settings *****
set terminal png truecolor enhanced font "Vera,9" size 1280,480
set style fill transparent solid 0.25 noborder
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

set multiplot layout 2, 3 title "CPU Usage \\& Load ".strftime("( %Y-%m-%dT%H:%M:%S )", time(0)+utc_offset)
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
set ylabel "Usage [%]"
set yrange [ 0 : 100 ]
set y2label "Load"
set y2range [ 0 : 2 ]
set y2tics format '%.0f'

# ***************************************************************** Legend *****
set key inside top left horizontal opaque box
set key samplen 0.1
set key reverse horizontal Left
set key maxcols 4

# ***************************************************************** Output *****
# ***** PLOT *****
set style data boxes

plot ifnamey \
      using ($1+utc_offset):($5+$6+$7+$8)     title "idle"    fc rgb "#229922" fs solid 1.0 \
  ,'' using ($1+utc_offset):($5+$6+$7)        title "waiting" fc "blue"        fs solid 1.0 \
  ,'' using ($1+utc_offset):($5+$6)           title "system"  fc "yellow"      fs solid 1.0 \
  ,'' using ($1+utc_offset):5                 title "user"    fc rgb "#bb0000" fs solid 1.0 \
  ,'' using ($1+utc_offset):2:4             notitle with filledcurves lc "white" axes x1y2 \
  ,'' using ($1+utc_offset):3                 title "load 5min" with lines lw 0.1 lc "black" axes x1y2

# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
#                                                                  LOWER ROW
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

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
set ylabel "Usage [%]"
set yrange [ 0 : 100 ]

# **************************************************************** Y2-axis *****
set y2label " "
set y2tics format " "
set y2tics border
set y2range [ 0 : 2 ]

# ***************************************************************** Legend *****
unset key

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

plot ifnamew \
      using ($1+utc_offset):($5+$6+$7+$8)     title "idle"    fc rgb "#229922" fs solid 1.0 \
  ,'' using ($1+utc_offset):($5+$6+$7)        title "waiting" fc "blue"        fs solid 1.0 \
  ,'' using ($1+utc_offset):($5+$6)           title "system"  fc "yellow"      fs solid 1.0 \
  ,'' using ($1+utc_offset):5                 title "user"    fc rgb "#bb0000" fs solid 1.0 \
  ,'' using ($1+utc_offset):2:4             notitle with filledcurves lc "white" axes x1y2 \
  ,'' using ($1+utc_offset):3                 title "load 5min" with lines lw 0.1 lc "black" axes x1y2



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
set yrange [ 0 : 100 ]
set y2range [ 0 : 2 ]

# ***************************************************************** Legend *****
unset key

# ***************************************************************** Output *****
set lmargin at screen LMPOS+0.001
set rmargin at screen MRPOS

# ***** PLOT *****
plot ifnamed \
      using ($1+utc_offset):($5+$6+$7+$8)     fc rgb "#229922" fs solid 1.0 \
  ,'' using ($1+utc_offset):($5+$6+$7)        fc "blue"        fs solid 1.0 \
  ,'' using ($1+utc_offset):($5+$6)           fc "yellow"      fs solid 1.0 \
  ,'' using ($1+utc_offset):5                 fc rgb "#bb0000" fs solid 1.0 \
  ,'' using ($1+utc_offset):2:4             notitle with filledcurves lc "white" axes x1y2 \
  ,'' using ($1+utc_offset):3                 with lines lw 0.1 lc "black" axes x1y2

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
set yrange [ 0 : 100 ]

# **************************************************************** Y2-axis *****
set y2label "Load"
set y2tics format '%.0f'
set y2range [0:2]
set y2tics border

# ***************************************************************** Legend *****
unset key

# ***************************************************************** Output *****
set lmargin at screen MRPOS+0.001
set rmargin at screen RMARG

# ***** PLOT *****
plot ifnameh \
      using ($1+utc_offset):($3+$4+$5+$6)     fc rgb "#229922" fs solid 1.0 \
  ,'' using ($1+utc_offset):($3+$4+$5)        fc "blue"        fs solid 1.0 \
  ,'' using ($1+utc_offset):($3+$4)           fc "yellow"      fs solid 1.0 \
  ,'' using ($1+utc_offset):3                 fc rgb "#bb0000" fs solid 1.0 \
  ,'' using ($1+utc_offset):2                 with lines lw 0.1 lc "black" axes x1y2

# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
#                                                                 FINALIZING
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

unset multiplot
