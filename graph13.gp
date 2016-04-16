#!/usr/bin/env gnuplot

# graph of network usage

# datafile
ifname = "/tmp/sql13.csv"
ofname = "/tmp/lnxdiagd/site/img/day13.png"

# ******************************************************* General settings *****
set terminal png truecolor enhanced font "Vera" 10 size 640,304
set datafile separator ';'
set datafile missing "NaN"    # Ignore missing values
set grid front
tz_offset = utc_offset / 3600 # GNUplot only works with UTC. Need to compensate
                              # for timezone ourselves.
set output ofname

# ************************************************************* Statistics *****
# stats to be calculated here of column 2 (UX-epoch)
stats ifname using 2 name "X" nooutput
X_min = X_min + utc_offset - 946684800
X_max = X_max + utc_offset - 946684800

# ************************************************************* Functions ******
# determine delta data
delta(x) = ( xD = x - old_x, old_x = x, xD <= 0 ? NaN : xD)
old_x = NaN

# ****************************************************************** Title *****

# Set top and bottom margins to 0 so that there is no space between plots.
# Fix left and right margins to make sure that the alignment is perfect.
# Turn off xtics for all plots except the bottom one.
# In order to leave room for axis and tic labels underneath, we ask for
# a 4-plot layout but only use the top 3 slots.
#
#set lmargin 3
#set rmargin 3
#unset xtics

set multiplot layout 2,1 title "Network Usage (eth0)"


################################################################################
################################### TOP PLOT ###################################
################################################################################

# ***************************************************************** X-axis *****
set xdata time               # Define that data on X-axis should be interpreted as time
set timefmt "%s"             # Time in log-file is given in Unix format
set format x "%R"            # Display time in 24 hour notation on the X axis
set xtics rotate by 40 right
set xrange [ X_min : X_max ]
unset xlabel

# ***************************************************************** Y-axis *****
##set ylabel "Usage []"
##set autoscale y
##set format y "%4.1s %c"
##set logscale y 2
set bmargin 0

# ***************************************************************** Output *****
# set arrow from graph 0,graph 0 to graph 0,graph 1 nohead lc rgb "red" front
# set arrow from graph 1,graph 0 to graph 1,graph 1 nohead lc rgb "green" front
##set object 1 rect from screen 0,0 to screen 1,1 behind
##set object 1 rect fc rgb "#eeeeee" fillstyle solid 1.0 noborder
##set object 2 rect from graph 0,0 to graph 1,1 behind
##set object 2 rect fc rgb "#ffffff" fillstyle solid 1.0 noborder

##set style data boxes
##set style fill solid noborder

plot ifname using ($2+utc_offset):(delta($6)*8/60) title "Download (eth0)" fc rgb "#bb0000"  \


################################################################################
################################## BOTTOM PLOT #################################
################################################################################

# ******************************************************* General settings *****
set timestamp 'created: %Y-%m-%d %H:%M' bottom

# ***************************************************************** X-axis *****
set xlabel "Date/Time"       # X-axis label
set xdata time               # Define that data on X-axis should be interpreted as time
set timefmt "%s"             # Time in log-file is given in Unix format
set format x "%R"            # Display time in 24 hour notation on the X axis
set xtics rotate by 40 right
set xrange [ X_min : X_max ]

# ***************************************************************** Y-axis *****
##set ylabel "Usage []"
##set autoscale y
##set format y "%4.1s %c"
##set logscale y 2
set tmargin 0
unset bmargin

# ***************************************************************** Output *****
# set arrow from graph 0,graph 0 to graph 0,graph 1 nohead lc rgb "red" front
# set arrow from graph 1,graph 0 to graph 1,graph 1 nohead lc rgb "green" front
##set object 1 rect from screen 0,0 to screen 1,1 behind
##set object 1 rect fc rgb "#eeeeee" fillstyle solid 1.0 noborder
##set object 2 rect from graph 0,0 to graph 1,1 behind
##set object 2 rect fc rgb "#ffffff" fillstyle solid 1.0 noborder

# ***** PLOT *****
##set style data boxes
##set style fill solid noborder


plot ifname using ($2+utc_offset):(delta($7)*8/60) title "Upload   (eth0)" fc rgb "#0000bb" \

unset multiplot
