#!/usr/bin/env gnuplot

# graph of count of loglines

# datafile
ifname = "/tmp/lnxdiagd/mysql/sql15d.csv"
ofname = "/tmp/lnxdiagd/site/img/day15.png"

# ******************************************************* General settings *****
set terminal png truecolor enhanced font "Vera,9" size 640,304
set datafile separator ';'
set datafile missing "NaN"    # Ignore missing values
set grid front
tz_offset = utc_offset / 3600 # GNUplot only works with UTC. Need to compensate
                              # for timezone ourselves.
set timestamp 'created: %Y-%m-%d %H:%M' bottom font "Vera,6"

# ************************************************************* Functions ******
# determine delta data
delta(x) = ( xD = x - old_x, old_x = x, xD <= 0 ? 0.1 : xD)
old_x = NaN

# ************************************************************* Statistics *****
# stats to be calculated here of column 2 (UX-epoch)
stats ifname using 2 name "X" nooutput

X_min = X_min + utc_offset - 946684800
X_max = X_max + utc_offset - 946684800

# ****************************************************************** Title *****
set title "Logging"

# ***************************************************************** X-axis *****
set xlabel "Date/Time"       # X-axis label
set xdata time               # Data on X-axis should be interpreted as time
set timefmt "%s"             # Time in log-file is given in Unix format
set format x "%R"            # Display time in 24 hour notation on the X axis
set xtics rotate by 40 right
set xrange [ X_min : X_max ]

# ***************************************************************** Y-axis *****
set ylabel "Lines []"
set autoscale y
set format y "%4.1s %c"
set logscale y 10

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
      using ($2+utc_offset):(delta($4+$5+$6+$7+$8+$9)) title "p5" fc "green"  \
  ,'' using ($2+utc_offset):(delta($4+$5+$6+$7+$8))    title "p4" fc "gold"   \
  ,'' using ($2+utc_offset):(delta($4+$5+$6+$7))       title "p3" fc "orange" \
  ,'' using ($2+utc_offset):(delta($4+$5+$6))          title "p2" fc "red"    \
  ,'' using ($2+utc_offset):(delta($4+$5))             title "p1" fc "blue"   \
  ,'' using ($2+utc_offset):(delta($4))                title "p0" fc "black"  \


#    using ($2+utc_offset):(delta($4+$5+$6+$7+$8+$9+$10+$11)) title "p0" fc "black"\
#,'' using ($2+utc_offset):(delta($5+$6+$7+$8+$9+$10+$11)) title "p1" fc "blue"\
#,'' using ($2+utc_offset):(delta($6+$7+$8+$9+$10+$11)) title "p2" fc "red"\
#,'' using ($2+utc_offset):(delta($7+$8+$9+$10+$11)) title "p3" fc "orange"\
#,'' using ($2+utc_offset):(delta($8+$9+$10+$11)) title "p4" fc "gold"\
#,'' using ($2+utc_offset):(delta($9+$10+$11)) title "p5" fc "yellow"\
#,'' using ($2+utc_offset):(delta($10+$11)) title "p6" fc "green" \
#,'' using ($2+utc_offset):(delta($11)) title "p7" fc "grey" \
