#!/usr/bin/gnuplot

reset

!iperf -c 192.168.17.206 -i 0.5 -f m -t 60 > a

#this is used for deleting first 6 lines 
!sed -i 1,+5d a

#used to delete last line
!sed '$d' a > cropped

!cat cropped | cut -c 7-10 > b
!cat cropped | cut -c 35-38 > c
!paste b c > d

!awk 'BEGIN{print "0.0  0.0"}{print}' d > e

set xlabel "time"
set ylabel "throughput (Mbps)"

set terminal png nocrop enhanced font arial 8 size 900,300
#set terminal png size 900, 300

set output "chart_1.png"

#table name below graph(naming curve by colour)
set key below

plot  'e' using 1:2 title "Throughput Performance" with lines

