#!/usr/bin/env gnuplot

# graph of CPU load

# datafiles
ifnameh = "/tmp/lnxdiagd/mysql/sql12h.csv"
ifnamed = "/tmp/lnxdiagd/mysql/sql12d.csv"
ifnamew = "/tmp/lnxdiagd/mysql/sql12w.csv"
set output ofname = "/tmp/lnxdiagd/site/img/day12.png"

# ******************************************************* General settings *****
set terminal png truecolor enhanced font "Vera,9" size 1280,320
set datafile separator ';'
set datafile missing "NaN"    # Ignore missing values
set grid
tz_offset = utc_offset / 3600 # GNUplot only works with UTC. Need to compensate
                              # for timezone ourselves.
# Positions of split between graphs
LMPOS = 0.40
MRPOS = 0.75
RMARG = 0.96

min(x,y) = (x < y) ? x : y
max(x,y) = (x > y) ? x : y

# ********************************************************* Statistics (R) *****
# stats to be calculated here of column 2 (UX-epoch)
stats ifnameh using 2 name "X" nooutput

Xh_min = X_min + utc_offset - 946684800
Xh_max = X_max + utc_offset - 946684800


# ********************************************************* Statistics (M) *****
# stats to be calculated here of column 2 (UX-epoch)
stats ifnamed using 2 name "X" nooutput

Xd_min = X_min + utc_offset - 946684800
Xd_max = X_max + utc_offset - 946684800


# ********************************************************* Statistics (L) *****
# stats to be calculated here of column 2 (UX-epoch)
stats ifnamew using 2 name "X" nooutput
Xw_min = X_min + utc_offset - 946684800
Xw_max = X_max + utc_offset - 946684800

set multiplot layout 1, 3 title "CPU Usage \\& Load ".strftime("( %Y-%m-%dT%H:%M )", time(0)+utc_offset)


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
set y2range [ 0 : 2 ]

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

set rmargin at screen LMPOS

# ***** PLOT *****
set style data boxes
set style fill solid noborder

plot ifnamew \
      using ($2+utc_offset):($10+$11+$12+$13) title "idle"    fc rgb "#229922"    \
  ,'' using ($2+utc_offset):($10+$11+$13)     title "waiting" fc "blue"           \
  ,'' using ($2+utc_offset):($10+$11)         title "system"  fc "yellow"         \
  ,'' using ($2+utc_offset):10                title "user"    fc rgb "#ccbb0000"  \
  ,'' using ($2+utc_offset):5                 title "load 5min" with lines lw 0.1 fc "black" axes x1y2



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
      using ($2+utc_offset):($10+$11+$12+$13) fc rgb "#229922"    \
  ,'' using ($2+utc_offset):($10+$11+$13)     fc "blue"           \
  ,'' using ($2+utc_offset):($10+$11)         fc "yellow"         \
  ,'' using ($2+utc_offset):10                fc rgb "#ccbb0000"  \
  ,'' using ($2+utc_offset):5                 with lines lw 0.1 fc "black" axes x1y2

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
#set autoscale y2
set y2range [0:2]
set y2tics border

# ***************************************************************** Legend *****
unset key

# ***************************************************************** Output *****
set lmargin at screen MRPOS+0.001
set rmargin at screen RMARG

# ***** PLOT *****
plot ifnameh \
      using ($2+utc_offset):($10+$11+$12+$13) fc rgb "#229922"    \
  ,'' using ($2+utc_offset):($10+$11+$13)     fc "blue"           \
  ,'' using ($2+utc_offset):($10+$11)         fc "yellow"         \
  ,'' using ($2+utc_offset):10                fc rgb "#ccbb0000"  \
  ,'' using ($2+utc_offset):5                 with lines lw 0.1 fc "black" axes x1y2

# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
#                                                                 FINALIZING
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

unset multiplot
