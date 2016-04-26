#!/usr/bin/env gnuplot

# graph of network usage

# datafile
ifname = "/tmp/sql13.csv"
ofname = "/tmp/lnxdiagd/site/img/day13.png"

# ******************************************************* General settings *****
set terminal png truecolor enhanced font "Vera" 9 size 640,320
set datafile separator ';'
set datafile missing "NaN"    # Ignore missing values
set grid front
tz_offset = utc_offset / 3600 # GNUplot only works with UTC. Need to compensate
                              # for timezone ourselves.
set output ofname

# ************************************************************* Functions ******
# determine delta data
delta(x) = ( xD = x - old_x, old_x = x, xD <= 0 ? NaN : xD)
lg(x)    = ( xL = x, xL == NaN ? NaN : log(xL) )
old_x = NaN

# ************************************************************* Statistics *****
# stats to be calculated here of column 2 (UX-epoch)
stats ifname using 2 name "X" nooutput
X_min = X_min + utc_offset - 946684800
X_max = X_max + utc_offset - 946684800

# stats to be calculated here of column 6 (Download bytes per minute)
stats ifname using (delta($6)) name "Ydn" nooutput
Ydn_min = 1024 * 8 / 60.
Ydn_max = Ydn_max * 8 / 60.

# stats to be calculated here of column 6 (Download bytes per minute)
stats ifname using (delta($7)) name "Yup" nooutput
Yup_min = 1024 * 8 / 60.
Yup_max = Yup_max * 8 / 60.

# ***************************************************************** Legend *****
set key inside top left nobox
set key samplen .5
set key reverse Left

set multiplot layout 2,1 title "Network Usage (eth0)"


################################################################################
################################### TOP PLOT ###################################
################################################################################

# ***************************************************************** X-axis *****
set xdata time               # Data on X-axis should be interpreted as time
set timefmt "%s"             # Time in log-file is given in Unix format
set format x ""
set xtics rotate by 40 right
set xrange [ X_min : X_max ]

# ***************************************************************** Y-axis *****
set ylabel "Speed [bits/sec]"
set format y "%3.0s %c"
set logscale y 10
set yrange [ Yup_min : Yup_max ]
set bmargin 0

# ***************************************************************** Output *****
set object 1 rect from screen 0,0 to screen 1,1 behind
set object 1 rect fc rgb "#eeeeee" fillstyle solid 1.0 noborder
set object 2 rect from graph 0,0 to graph 1,1 behind
set object 2 rect fc rgb "#ffffff" fillstyle solid 1.0 noborder

##set style data boxes
##set style fill solid noborder

plot ifname using ($2+utc_offset):(delta($7)*8/60) title "Upload   (eth0)" fc rgb "#0000bb" with dots\

unset object 1

################################################################################
################################## BOTTOM PLOT #################################
################################################################################

# ******************************************************* General settings *****
set timestamp 'created: %Y-%m-%d %H:%M' bottom font "Vera,6"

# ***************************************************************** X-axis *****
set xlabel "Date/Time"       # X-axis label
set xdata time               # Data on X-axis should be interpreted as time
set timefmt "%s"             # Time in log-file is given in Unix format
set format x "%R"            # Display time in 24 hour notation on the X axis
set xtics rotate by 40 right
set xrange [ X_min : X_max ]

# ***************************************************************** Y-axis *****
set ylabel " "
set logscale y 10
set yrange [ Ydn_min : Ydn_max ] reverse
set tmargin 0
unset bmargin

# ***************************************************************** Output *****
##set object 1 rect from screen 0,0 to screen 1,1 behind
##set object 1 rect fc rgb "#eeeeee" fillstyle solid 1.0 noborder
set object 2 rect from graph 0,0 to graph 1,1 behind
set object 2 rect fc rgb "#ffffff" fillstyle solid 1.0 noborder

# ***** PLOT *****
##set style data boxes
##set style fill solid noborder

plot ifname using ($2+utc_offset):(delta($6)*8/60) title "Download (eth0)" fc rgb "#bb0000"  with dots \

unset object 2
unset multiplot
