#!/bin/bash
# Send RCT values to database
# This script assumes:
# * you have a .my.cnf file and it's executed on the MariaDB server
# * the DB is called "hausdaten"
# * the table is called "rct"
# If not, adapt the mysql command in the last line accordingly.


# INIT
rct_ip_address="192.168.178.101"
timestamp=$(date "+%s")

# FUNCTION FOR RETRIEVING DATA FROM RCT
get_rct_value () {

    counter=0
    result=""

    # Try to read value a few times or until result is not empty anymore
    while [ -z "$result" ] && [ "$counter" -lt 3 ]; do

	# Pause if not on first run (avoid hammering)
	if [ "$counter" -gt 0 ]; then sleep 1; fi

	# Get results from inverter
	result=$(timeout 5 /usr/local/bin/rctclient read-value --host $rct_ip_address --id $1)

	let counter++

    done

    # In case of RCT inverter we add another pause to make sure we don't
    # hammer with the inquiry that might follow. It's sensitive.
    sleep 1

}

# READ VALUES

# String 1
get_rct_value 0xB5317B78
edc1=$(echo "scale=2;$result/1"|bc)

get_rct_value 0xAA9AA253
edc2=$(echo "scale=2;$result/1"|bc)

get_rct_value 0x4E49AEC5
eac=$(echo "scale=2;$result/1"|bc)

# Haus-Power: negativ heißt Einspeisung, positiv heißt Netzbezug
get_rct_value 0x1AC87AA0
load_house=$(echo "scale=2;$result/1"|bc)

get_rct_value 0x91617C58
grid_power=$(echo "scale=2;$result/1"|bc)

# Batterie-Power: negativ beim Laden, positiv beim Entladen
#get_rct_value 0xBD008E29
get_rct_value 0x1156DFD0
battery_power=$(echo "scale=2;$result/1"|bc)

edc=$(echo "scale=0;($edc1+$edc2-$load_house+$grid_power)/1"|bc)
bp=$(echo "scale=0;($battery_power)/-1"|bc)

if [[ $bp -gt 2000 && $bp -gt $edc ]]; then 
    battery_power=$((-edc))
    echo "$bp <-> $battery_power out of range"
fi

# State of Charge
get_rct_value 0x959930BF
soc=$(echo "scale=2;$result/1"|bc)
if [[ $soc -gt 1.0 ]]; then
	soc=1.0
fi
if [[ $soc -lt 0.0 ]]; then
	soc=0.0
fi
# WRITE VALUES TO DB
/bin/echo "INSERT INTO rct (timestamp,edc1,edc2,load_house,grid_power,battery_power,soc,eac) VALUES ('$timestamp', '$edc1', '$edc2', '$load_house', '$grid_power', '$battery_power', '$soc', '$eac');" | sudo /usr/bin/mysql hausdaten
