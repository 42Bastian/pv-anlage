#!/bin/bash
while true; do
    # Wait for WR to appear
    while true; do
	ping 192.168.178.101 -c 1 -W 1 >/dev/null
	r=$?
	if [ $r -eq 0 ]; then
		break
	fi
	echo "Ping failed"
	sleep 30
    done
    printf -v today "%(%d%m%y)T"
    tomorrow=$today
    fn=~/wr_logs/wr_$today.log
    first=1
    while [ $today == $tomorrow ]; do
	# Check if WR still alive
	ping 192.168.178.101 -c 1 -W 1 >/dev/null
	r=$?
	if [ $r -eq 1 ]; then
	    echo "Lost connection to WR"
	    break
	fi
	printf -v delay "%(%S)T"
	delay=${delay##0}
	if [[ $delay -ge 60 ]]; then
	    delay=$((90-delay))
	else
	    delay=$((60-delay))
	fi
#	echo "delay $delay"
	sleep $delay
	printf -v d "%(%H:%M:%S)T"
	./rct-logging.sh
	printf -v tomorrow "%(%d%m%y)T"
	first=0
    done
done
