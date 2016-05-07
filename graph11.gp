#!/usr/bin/env gnuplot

# graph of CPU temperature

# datafiles
ifnameh = "/tmp/lnxdiagd/mysql/sql11h.csv"
ifnamed = "/tmp/lnxdiagd/mysql/sql11d.csv"
ifnamew = "/tmp/lnxdiagd/mysql/sql11w.csv"
set output ofname = "/tmp/lnxdiagd/site/img/day11.png"

# ******************************************************* General settings *****
set terminal png truecolor enhanced font "Vera,9" size 1280,304
set datafile separator ';'
set datafile missing "NaN"    # Ignore missing values
set grid
tz_offset = utc_offset / 3600 # GNUplot only works with UTC. Need to compensate
                              # for timezone ourselves.


# ********************************************************* Statistics (R) *****
# stats to be calculated here of column 2 (UX-epoch)
stats ifnameh using 2 name "X" nooutput

Xh_min = X_min + utc_offset - 946684800
Xh_max = X_max + utc_offset - 946684800

# stats to be calculated here for Y-axes
stats ifnameh using 4 name "Y" nooutput
Yh_min = Y_min * 0.90
Yh_max = Y_max * 1.10

# ********************************************************* Statistics (M) *****
# stats to be calculated here of column 2 (UX-epoch)
stats ifnamed using 2 name "X" nooutput

Xd_min = X_min + utc_offset - 946684800
Xd_max = X_max + utc_offset - 946684800

# stats to be calculated here for Y-axes
stats ifnameh using 4 name "Y" nooutput
Yd_min = Y_min * 0.90
Yd_max = Y_max * 1.10


# ********************************************************* Statistics (L) *****
# stats to be calculated here of column 2 (UX-epoch)
stats ifnamew using 2 name "X" nooutput
Xw_min = X_min + utc_offset - 946684800
Xw_max = X_max + utc_offset - 946684800

# stats for Y-axis
stats ifnameh using 4 name "Y" nooutput
Yw_min = Y_min * 0.90
Yw_max = Y_max * 1.10


set multiplot layout 1, 3 title "CPU Temperature"


# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
#                                                      RIGHT PLOT: last hour
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


# ***************************************************************** X-axis *****
set xlabel "Date/Time"       # X-axis label
set xdata time               # Data on X-axis should be interpreted as time
set timefmt "%s"             # Time in log-file is given in Unix format
set format x "%R"            # Display time in 24 hour notation on the X axis
set xtics rotate by 40 right
set xrange [ Xh_min : Xh_max ]

# ***************************************************************** Y-axis *****
set ylabel "Temperature [degC]"
#set yrange [10:20]
#set autoscale y
set yrange [ Yh_min : Yh_max ]

# ***************************************************************** Legend *****
set key outside bottom center horizontal box
set key samplen .5
set key reverse Left

# ***************************************************************** Output *****
# set arrow from graph 0,graph 0 to graph 0,graph 1 nohead lc rgb "red" front
# set arrow from graph 1,graph 0 to graph 1,graph 1 nohead lc rgb "green" front
#set object 1 rect from screen 0,0 to screen 1,1 behind
#set object 1 rect fc rgb "#eeeeee" fillstyle solid 1.0 noborder
#set object 2 rect from graph 0,0 to graph 1,1 behind
#set object 2 rect fc rgb "#ffffff" fillstyle solid 1.0 noborder

# ***** PLOT *****
plot ifnameh \
      using ($2+utc_offset):4 title " Temperature [degC]" with points pt 5 ps 0.2 fc rgb "#ccbb0000" \



# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
#                                                     MIDDLE PLOT:  past day
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


# ****************************************************************** Title *****
set title "CPU Temperature"


# ***** PLOT *****
plot ifnameh \
      using ($2+utc_offset):4 title " Temperature [degC]" with points pt 5 ps 0.2 fc rgb "#ccbb0000" \

# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
#                                                       LEFT PLOT: past week
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

# ****************************************************************** Title *****
set title "CPU Temperature"


# ***** PLOT *****
plot ifnameh \
      using ($2+utc_offset):4 title "LEFT" with points pt 5 ps 0.2 fc rgb "#ccbb0000" \

# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
#                                                                 FINALIZING
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
set timestamp 'created: %Y-%m-%d %H:%M' bottom font "Vera,6"
unset multiplot
