#!/usr/bin/env gnuplot

# graph of CPU temperature

# datafile
ifname = "/tmp/sql11.csv"
ofname = "/tmp/lnxdiagd/site/img/day11.png"

# ******************************************************* General settings *****
# set terminal png font "Vera" 11 size 640,480
set terminal png font "Vera" 10 size 640,304
set datafile separator ';'
set datafile missing "NaN"    # Ignore missing values
set grid
tz_offset = utc_offset / 3600 # GNUplot only works with UTC. Need to compensate
                              # for timezone ourselves.
set timestamp 'created: %Y-%m-%d %H:%M' bottom

# ************************************************************* Statistics *****
# stats to be calculated here of column 2 (UX-epoch)
stats ifname using 2 name "X" nooutput

X_min = X_min + utc_offset - 946684800
X_max = X_max + utc_offset - 946684800

# ****************************************************************** Title *****
set title "CPU Temperature"
#"-".utc_offset."-"

# ***************************************************************** X-axis *****
set xlabel "Date/Time"       # X-axis label
set xdata time               # Define that data on X-axis should be interpreted as time
set timefmt "%s"             # Time in log-file is given in Unix format
set format x "%R"            # Display time in 24 hour notation on the X axis
set xtics rotate by 40 right
set xrange [ X_min : X_max ]

# ***************************************************************** Y-axis *****
set ylabel "Temperature [degC]"
#set yrange [10:20]
set autoscale y

# **************************************************************** Y2-axis *****
# set y2label "Temperature [degC]"
# set autoscale y2
# set y2tics border

# ***************************************************************** Legend *****
set key outside bottom center horizontal box
set key samplen .2
set key reverse Left

# ***************************************************************** Output *****
set arrow from graph 0,graph 0 to graph 0,graph 1 nohead lc rgb "red" front
#set arrow from graph 1,graph 0 to graph 1,graph 1 nohead lc rgb "green" front
set object 1 rect from screen 0,0 to screen 1,1 behind
set object 1 rect fc rgb "#eeeeee" fillstyle solid 1.0 noborder
set object 2 rect from graph 0,0 to graph 1,1 behind
set object 2 rect fc rgb "#ffffff" fillstyle solid 1.0 noborder
set output ofname

# ***** PLOT *****
plot ifname  using ($2+utc_offset):4 title " Temperature [degC]" with points pt 5 ps 0.2 \
#    ,       using ($2+utc_offset):4 title " Temperature [degC]" axes x1y2  with dots\
