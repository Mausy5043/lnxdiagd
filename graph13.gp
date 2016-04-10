#!/usr/bin/env gnuplot

# graph of CPU load

# datafile
ifname = "/tmp/sql13.csv"
ofname = "/tmp/lnxdiagd/site/img/day13.png"

# ******************************************************* General settings *****
# set terminal png font "Vera" 11 size 640,480
set terminal png truecolor enhanced font "Vera" 10 size 640,304
set datafile separator ';'
set datafile missing "NaN"    # Ignore missing values
set grid front
tz_offset = utc_offset / 3600 # GNUplot only works with UTC. Need to compensate
                              # for timezone ourselves.
set timestamp 'created: %Y-%m-%d %H:%M' bottom

# ************************************************************* Statistics *****
# stats to be calculated here of column 2 (UX-epoch)
stats ifname using 2 name "X" nooutput
X_min = X_min + utc_offset - 946684800
X_max = X_max + utc_offset - 946684800

stats ifname using 7 name "upY" nooutput
Y_max = upY_max * 1.1

stats ifname using 6 name "dnY" nooutput
Y_min = dnY_max * -1.1

# ************************************************************* Functions ******
# determine delta data
delta(x) = ( xD = x - old_x, old_x = x, xD < 0 ? 0 : xD)
old_x = NaN

# ****************************************************************** Title *****
set title "Network Usage (eth0)"

# ***************************************************************** X-axis *****
set xlabel "Date/Time"       # X-axis label
set xdata time               # Define that data on X-axis should be interpreted as time
set timefmt "%s"             # Time in log-file is given in Unix format
set format x "%R"            # Display time in 24 hour notation on the X axis
set xtics rotate by 40 right
set xrange [ X_min : X_max ]

# ***************************************************************** Y-axis *****
set ylabel "Usage []"
set yrange [:100]
set autoscale y
set format y "%3.0s %c"
set yrange [ Y_min : Y_max ]

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
set style fill transparent solid 0.05 noborder

plot ifname \
       using ($2+utc_offset):(delta($6)*-1*8/60) title "Download (eth0)" fc rgb "#33bb0000"  \
  , '' using ($2+utc_offset):(delta($7)*8/60)    title "Upload   (eth0)" fc rgb "#330000bb" \
