#!/usr/bin/env gnuplot

# graph of memory usage

# datafile
ifname = "/tmp/sql14.csv"
ofname = "/tmp/lnxdiagd/site/img/day14.png"

# ******************************************************* General settings *****
# set terminal png font "Vera" 11 size 640,480
set terminal png truecolor enhanced font "Vera" 10 size 640,304
set datafile separator ';'
set datafile missing "NaN"    # Ignore missing values
set grid front
tz_offset = utc_offset / 3600 # GNUplot only works with UTC. Need to compensate
                              # for timezone ourselves.
set timestamp 'created: %Y-%m-%d %H:%M' bottom font "Vera,8"

# ************************************************************* Statistics *****
# stats to be calculated here of column 2 (UX-epoch)
stats ifname using 2 name "X" nooutput

X_min = X_min + utc_offset - 946684800
X_max = X_max + utc_offset - 946684800

# ****************************************************************** Title *****
set title "Memory Usage"

# ***************************************************************** X-axis *****
set xlabel "Date/Time"       # X-axis label
set xdata time               # Define that data on X-axis should be interpreted as time
set timefmt "%s"             # Time in log-file is given in Unix format
set format x "%R"            # Display time in 24 hour notation on the X axis
set xtics rotate by 40 right
set xrange [ X_min : X_max ]

# ***************************************************************** Y-axis *****
set ylabel "Usage []"
set autoscale y
set format y "%4.1s %c"

# **************************************************************** Y2-axis *****
# set y2label "Load"
# set autoscale y2
# set y2tics border

# ***************************************************************** Legend *****
set key outside bottom center horizontal box
set key samplen .2
set key reverse Left

# ***************************************************************** Output *****
# set arrow from graph 0,graph 0 to graph 0,graph 1 nohead lc rgb "red" front
# set arrow from graph 1,graph 0 to graph 1,graph 1 nohead lc rgb "green" front
set object 1 rect from screen 0,0 to screen 1,1 behind
set object 1 rect fc rgb "#eeeeee" fillstyle solid 1.0 noborder
set object 2 rect from graph 0,0 to graph 1,1 behind
set object 2 rect fc rgb "#ffffff" fillstyle solid 1.0 noborder
set output ofname

# ***** PLOT *****
set style data boxes
set style fill solid noborder

plot ifname \
       using ($2+utc_offset):($5+$6+$7+$8) title "free"    fc rgb "#229922" \
  , '' using ($2+utc_offset):($5+$6+$7)    title "cached"  fc "yellow"      \
  , '' using ($2+utc_offset):($5+$6)       title "buffers" fc "blue"     \
  , '' using ($2+utc_offset):5             title "user"    fc rgb "#bb0000"
