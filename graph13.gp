#!/usr/bin/env gnuplot

# graph of CPU temperature

# datafiles
ifnameh = "/tmp/lnxdiagd/mysql/sql13h.csv"
ifnamed = "/tmp/lnxdiagd/mysql/sql13d.csv"
ifnamew = "/tmp/lnxdiagd/mysql/sql13w.csv"
set output "/tmp/lnxdiagd/site/img/day13.png"

# ******************************************************* General settings *****
set terminal png truecolor enhanced font "Vera,9" size 1280,320
set datafile separator ';'
set datafile missing "NaN"    # Ignore missing values
set grid
tz_offset = utc_offset / 3600 # GNUplot only works with UTC. Need to compensate
                              # for timezone ourselves.
# Positions of split between graphs
LMARG = 0.06
LMPOS = 0.40
MRPOS = 0.73
RMARG = 0.94

# ************************************************************* Functions ******
# determine delta data
delta(x) = ( xD = x - old_x, old_x = x, xD <= 0 ? 0.1 : xD)
# lg(x)    = ( xL = x, xL == NaN ? NaN : log(xL) )
old_x = NaN

min(x,y) = (x < y) ? x : y
max(x,y) = (x > y) ? x : y

# ********************************************************* Statistics (R) *****
# stats to be calculated here of column 2 (UX-epoch)
stats ifnameh using 2 name "X" nooutput
Xh_min = X_min + utc_offset - 946684800
Xh_max = X_max + utc_offset - 946684800

# stats to be calculated here of column 7 (Download bytes per minute)
stats ifnameh using (delta($7)) name "Yh" nooutput

# ********************************************************* Statistics (M) *****
# stats to be calculated here of column 2 (UX-epoch)
stats ifnamed using 2 name "X" nooutput
Xd_min = X_min + utc_offset - 946684800
Xd_max = X_max + utc_offset - 946684800

# stats to be calculated here of column 7 (Download bytes per minute)
stats ifnamed using (delta($7)) name "Yd" nooutput

# ********************************************************* Statistics (L) *****
# stats to be calculated here of column 2 (UX-epoch)
stats ifnamew using 2 name "X" nooutput
Xw_min = X_min + utc_offset - 946684800
Xw_max = X_max + utc_offset - 946684800

# stats to be calculated here of column 7 (Download bytes per minute)
stats ifnameh using (delta($7)) name "Yw" nooutput

Ymax = max(max(Yd_max, Yh_max), Yw_max) * 8 / 60.
Ymin = 1024 * 8 / 60.

set multiplot layout 2, 3 title "Network load ".strftime("( %Y-%m-%dT%H:%M:%S )", time(0)+utc_offset)


# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
#                                                    TOP LEFT PLOT: past week
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


# ***************************************************************** X-axis *****
set xdata time               # Data on X-axis should be interpreted as time
set timefmt "%s"             # Time in log-file is given in Unix format
set format x ""            # Display time in 24 hour notation on the X axis
set xrange [ Xw_min : Xw_max ]

# ***************************************************************** Y-axis *****
set ylabel "Network load [bits/sec]"
set yrange [ Ymin : Ymax ]
set format y "%3.0s%c"
# set autoscale y
set bmargin 0

# ***************************************************************** Legend *****
set key inside top left horizontal box
set key samplen 1
set key reverse Left

# ***************************************************************** Output *****

set lmargin at screen LMARG
set rmargin at screen LMPOS

# ***** PLOT *****
plot ifnamew \
      using ($2+utc_offset):(delta($7)*8/60) title "Upload (eth0)" with lines lc rgb "#cc0000bb" lw 1\

# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
#                                                 TOP MIDDLE PLOT:  past day
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

# ***************************************************************** X-axis *****
set xdata time               # Data on X-axis should be interpreted as time
set timefmt "%s"             # Time in log-file is given in Unix format
set format x ""            # Display time in 24 hour notation on the X axis
set xrange [ Xd_min : Xd_max ]

# ***************************************************************** Y-axis *****
set ylabel " "
set ytics format " "
set yrange [ Ymin : Ymax ]

# ***************************************************************** Legend *****
unset key

# ***************************************************************** Output *****
set lmargin at screen LMPOS+0.001
set rmargin at screen MRPOS

# ***** PLOT *****
plot ifnamed \
      using ($2+utc_offset):(delta($7)*8/60) with lines lc rgb "#cc0000bb" lw 1\

# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
#                                                  TOP RIGHT PLOT: past hour
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

# ***************************************************************** X-axis *****
set xdata time               # Data on X-axis should be interpreted as time
set timefmt "%s"             # Time in log-file is given in Unix format
set format x ""            # Display time in 24 hour notation on the X axis
set xrange [ Xh_min : Xh_max ]
set xtics textcolor rgb "red"

# ***************************************************************** Y-axis *****
set ylabel " "
set ytics format " "
set yrange [ Ymin : Ymax ]

# ***************************************************************** Legend *****
unset key

# ***************************************************************** Output *****
set lmargin at screen MRPOS+0.001
set rmargin at screen RMARG

# ***** PLOT *****
plot ifnameh \
      using ($2+utc_offset):(delta($7)*8/60) with lines lc rgb "#cc0000bb" lw 1\


################################################################################
################################## BOTTOM PLOT #################################
################################################################################


# ********************************************************* Statistics (R) *****
# stats to be calculated here of column 6 (Download bytes per minute)
stats ifnameh using (delta($6)) name "Yh" nooutput

# ********************************************************* Statistics (M) *****
# stats to be calculated here of column 6 (Download bytes per minute)
stats ifnamed using (delta($6)) name "Yd" nooutput

# ********************************************************* Statistics (L) *****
# stats to be calculated here of column 6 (Download bytes per minute)
stats ifnameh using (delta($6)) name "Yw" nooutput

Ymax = max(max(Yd_max, Yh_max), Yw_max) * 8 / 60.
#Ymin = min(min(Yd_min, Yh_min), Yw_min) -1
Ymin = 1024 * 8 / 60.

# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
#                                                    BTM LEFT PLOT: past week
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


# ***************************************************************** X-axis *****
set xlabel "past week"       # X-axis label
set xdata time               # Data on X-axis should be interpreted as time
set timefmt "%s"             # Time in log-file is given in Unix format
set format x "%a %d"            # Display time in 24 hour notation on the X axis
set xrange [ Xw_min : Xw_max ]

# ***************************************************************** Y-axis *****
set ylabel "Network load [bits/sec]"
set yrange [ Ymin : Ymax ] reverse
set format y "%3.0s%c"
# set autoscale y
set tmargin 0
unset bmargin

# ***************************************************************** Legend *****
set key inside top left horizontal box
set key samplen 1
set key reverse Left

# ***************************************************************** Output *****

set lmargin at screen LMARG
set rmargin at screen LMPOS

# ***** PLOT *****
plot ifnamew \
      using ($2+utc_offset):(delta($6)*8/60) title "Upload (eth0)" with lines lc rgb "#ccbb0000" lw 1\

# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
#                                                 BTM MIDDLE PLOT:  past day
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
set yrange [ Ymin : Ymax ] reverse

# ***************************************************************** Legend *****
unset key

# ***************************************************************** Output *****
set lmargin at screen LMPOS+0.001
set rmargin at screen MRPOS

# ***** PLOT *****
plot ifnamed \
      using ($2+utc_offset):(delta($6)*8/60) with lines lc rgb "#ccbb0000" lw 1\

# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
#                                                  BTM RIGHT PLOT: past hour
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
set yrange [ Ymin : Ymax ] reverse

# ***************************************************************** Legend *****
unset key

# ***************************************************************** Output *****
set lmargin at screen MRPOS+0.001
set rmargin at screen RMARG

# ***** PLOT *****
plot ifnameh \
      using ($2+utc_offset):(delta($6)*8/60) with lines lc rgb "#ccbb0000" lw 1\

# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
#                                                                 FINALIZING
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

unset multiplot
