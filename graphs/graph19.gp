#!/usr/bin/env gnuplot

# graph of HD temperatures

# datafiles
ifnameh = "/tmp/lnxdiagd/mysql4gnuplot/sql19h.csv"
ifnamed = "/tmp/lnxdiagd/mysql4gnuplot/sql19d.csv"
ifnamew = "/tmp/lnxdiagd/mysql4gnuplot/sql19w.csv"
ifnamey = "/tmp/lnxdiagd/mysql4gnuplot/sql19y.csv"
set output "/tmp/lnxdiagd/site/img/day19.png"

# ******************************************************* General settings *****
set terminal png truecolor enhanced font "Vera,9" size 1280,480
#set terminal png enhanced font "Vera,9" size 1280,480
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

# stats to be calculated here for Y-axes
stats ifnameh using 2 name "Yh" nooutput
Ymax = Yh_max
Ymin = Yh_min
stats ifnameh using 3 name "Yh" nooutput
Ymax = max(Yh_max, Ymax)
Ymin = min(Yh_min, Ymin)
stats ifnameh using 4 name "Yh" nooutput
Ymax = max(Yh_max, Ymax)
Ymin = min(Yh_min, Ymin)
stats ifnameh using 5 name "Yh" nooutput
Ymax = max(Yh_max, Ymax)
Ymin = min(Yh_min, Ymin)
stats ifnameh using 6 name "Yh" nooutput
Yh_max = max(Yh_max, Ymax)
Yh_min = min(Yh_min, Ymin)

# ********************************************************* Statistics (M) *****
# stats to be calculated here of column 2 (UX-epoch)
stats ifnamed using 1 name "X" nooutput

Xd_min = X_min + utc_offset - epoch_compensate
Xd_max = X_max + utc_offset - epoch_compensate

# stats to be calculated here for Y-axes
stats ifnamed using 2 name "Yd" nooutput
Ymax = Yd_max
Ymin = Yd_min
stats ifnamed using 3 name "Yd" nooutput
Ymax = max(Yd_max, Ymax)
Ymin = min(Yd_min, Ymin)
stats ifnamed using 4 name "Yd" nooutput
Ymax = max(Yd_max, Ymax)
Ymin = min(Yd_min, Ymin)
stats ifnamed using 5 name "Yd" nooutput
Ymax = max(Yd_max, Ymax)
Ymin = min(Yd_min, Ymin)
stats ifnamed using 6 name "Yd" nooutput
Yd_max = max(Yd_max, Ymax)
Yd_min = min(Yd_min, Ymin)

# ********************************************************* Statistics (L) *****
# stats to be calculated here of column 2 (UX-epoch)
stats ifnamew using 1 name "X" nooutput
Xw_min = X_min + utc_offset - epoch_compensate
Xw_max = X_max + utc_offset - epoch_compensate

# stats for Y-axis
stats ifnamew using 2 name "Yw" nooutput
Ymax = Yw_max
Ymin = Yw_min
stats ifnamew using 3 name "Yw" nooutput
Ymax = max(Yw_max, Ymax)
Ymin = min(Yw_min, Ymin)
stats ifnamew using 4 name "Yw" nooutput
Ymax = max(Yw_max, Ymax)
Ymin = min(Yw_min, Ymin)
stats ifnamew using 5 name "Yw" nooutput
Ymax = max(Yw_max, Ymax)
Ymin = min(Yw_min, Ymin)
stats ifnamew using 6 name "Yw" nooutput
Yw_max = max(Yw_max, Ymax)
Yw_min = min(Yw_min, Ymin)

Ymax = max(max(Yd_max, Yh_max), Yw_max) +1
Ymin = min(min(Yd_min, Yh_min), Yw_min) -1

set multiplot layout 1, 3 title "Disk Temperatures ".strftime("( %Y-%m-%dT%H:%M:%S )", time(0)+utc_offset)


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
set ylabel "Temperature [degC]"
set yrange [ Ymin : Ymax ]

# ***************************************************************** Legend *****
set key inside top left horizontal box
set key samplen 1
set key reverse Left

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
plot ifnamew \
      using ($1+utc_offset):2 title "SDD [degC]" with lines lw 0.1 fc rgb "black" \
  ,'' using ($1+utc_offset):3 title "disk.1" with lines lw 0.1 fc rgb "#ccbb0000" \
  ,'' using ($1+utc_offset):4 title ".2" with lines lw 0.1 fc rgb "#229922" \
  ,'' using ($1+utc_offset):5 title ".3" with lines lw 0.1 fc rgb "#ff00ff" \
  ,'' using ($1+utc_offset):6 title ".4" with lines lw 0.1 fc "blue" \



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
set yrange [ Ymin : Ymax ]

# ***************************************************************** Legend *****
unset key

# ***************************************************************** Output *****
set lmargin at screen LMPOS+0.001
set rmargin at screen MRPOS

# ***** PLOT *****
plot ifnamed \
      using ($1+utc_offset):2 with lines lw 0.1 fc rgb "black" \
  ,'' using ($1+utc_offset):3 with lines lw 0.1 fc rgb "#ccbb0000" \
  ,'' using ($1+utc_offset):4 with lines lw 0.1 fc rgb "#229922" \
  ,'' using ($1+utc_offset):5 with lines lw 0.1 fc rgb "#ff00ff" \
  ,'' using ($1+utc_offset):6 with lines lw 0.1 fc "blue" \

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
set yrange [ Ymin : Ymax ]

# ***************************************************************** Legend *****
unset key

# ***************************************************************** Output *****
set lmargin at screen MRPOS+0.001
set rmargin at screen RMARG

# ***** PLOT *****
plot ifnameh \
      using ($1+utc_offset):2 with lines lw 0.1 fc rgb "black" \
  ,'' using ($1+utc_offset):3 with lines lw 0.1 fc rgb "#ccbb0000" \
  ,'' using ($1+utc_offset):4 with lines lw 0.1 fc rgb "#229922" \
  ,'' using ($1+utc_offset):5 with lines lw 0.1 fc rgb "#ff00ff" \
  ,'' using ($1+utc_offset):6 with lines lw 0.1 fc "blue" \

# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
#                                                                 FINALIZING
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

unset multiplot
