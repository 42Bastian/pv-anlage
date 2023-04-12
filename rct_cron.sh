#!/bin/bash
ping 192.168.178.101 -c 1 -W 1 >/dev/null
r=$?
if [ $r -ne 0 ]; then
	exit
fi	
/home/pi/grf/rct-logging.sh &>>~/grf/rct.log

