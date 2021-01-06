#!/bin/bash

case $1 in
    cpu )
	echo '  0%'
	
	if [ -x "/bin/mpstat" ]; then
	    while true; do
		icon=' '
		val=$(mpstat 1 1 | tail -1 | awk '{ printf "%2d%", 100 - $12 }')
		if [ -f /sys/devices/system/cpu/intel_pstate/no_turbo ]; then
		    no_turbo=`cat /sys/devices/system/cpu/intel_pstate/no_turbo`
		    if [[ ${no_turbo} = 0 ]]; then
			icon='%{T4} ⚡ %{T-}'
		    fi
		fi
		
		echo "$icon$val"
		sleep 1
	    done
	else
	    echo "Not found /bin/mpstat." >&2
	    exit 1
 	fi
	;;
    mem )
	icon=''
	while true; do
            val=$(free -m | awk '/Mem:/ {OFMT="%.2fGB"; print $3/1000}')
	    echo "$icon $val"
	    sleep 2
	done
	;;
    show )
	case $2 in
	    cpu )
		polybar-msg cmd hide.mem
		polybar-msg cmd show.cpu
		;;
	    mem )
		polybar-msg cmd hide.cpu
		polybar-msg cmd show.mem
		;;
	esac
	exit
	;;
    * )
	exit 1
	;;
esac


