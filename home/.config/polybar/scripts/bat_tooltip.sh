#!/bin/bash

declare list_bat=(
    'max170xx_battery'
    'BAT0'
    -1
)

for i in "${!list_bat[@]}"; do
    if [[ -e /sys/class/power_supply/${list_bat[$i]} ]]; then
	BAT=${list_bat[$i]}
	break
    elif [[ $i -eq $(( ${#list_bat[@]} - 1)) ]]; then
	echo "There's no battery." >&2
	exit 1
    fi
done

capacity=$(cat /sys/class/power_supply/$BAT/capacity)
status=$(cat /sys/class/power_supply/$BAT/status)

declare capacity_icons=(
    80 'full'
    50 'good'
    26 'low'
    16 'caution'
    0  'empty'
)

for (( i=1; i<=$((${#capacity_icons[@]}/2)); i++ )); do
    if [[ "${capacity}" -ge "${capacity_icons[i*2-2]}" ]]; then
	icon_bat="battery-${capacity_icons[i*2-1]}"
	break
    fi
done

if [[ ${status} = "Discharging" ]]; then
    if [[ $LANG = "ja_JP.UTF-8" ]]; then
	msg_title="バッテリーを使用中"
    else
	msg_title="Battery Discharging"
    fi
else
    icon_bat="${icon_bat}-charging"
    if [[ $LANG = "ja_JP.UTF-8" ]]; then
	msg_title="バッテリーを充電中"
    else
	msg_title="Battery Charging"
    fi
fi

if [ -e /sys/class/power_supply/$BAT/current_avg ]; then
    current_avg=$(cat /sys/class/power_supply/$BAT/current_avg)
    voltage_avg=$(cat /sys/class/power_supply/$BAT/voltage_avg)

    if [[ $LANG = "ja_JP.UTF-8" ]]; then
	msg="現在のワット数:"
    else
	msg="Current wattage:"
    fi
    
    watt_fmt=$(echo $current_avg $voltage_avg | awk '{ OFMT="%+.2fW"; print $1/1000000.0 * $2/1000000.0 }')
    msg="$msg $watt_fmt"
    
else
    energy_now=$(cat /sys/class/power_supply/$BAT/energy_now)
    
    if [[ ${status} = "Discharging" ]]; then
	energy=$energy_now
	rate_h=$(cat /sys/class/power_supply/$BAT/power_now)
	
	if [[ $LANG = "ja_JP.UTF-8" ]]; then
	    msg="残り あと"
	else
	    msg="remaining."
	fi
    else
	energy_full=$(cat /sys/class/power_supply/$BAT/energy_full)
	energy=$((energy_full - energy_now))
	rate_h=$(cat /sys/class/power_supply/$BAT/voltage_now)
	
	if [[ $LANG = "ja_JP.UTF-8" ]]; then
	    msg="満充電まで あと"
	else
	    msg="until fully charged."
	fi
    fi

    rem=`awk "BEGIN { print $energy / $rate_h }"`
    rem_h=`awk "BEGIN { printf \"%02d\", int($rem) }"`
    rem_m=`awk "BEGIN { x = int(($rem - $rem_h) * 60); printf \"%02d\", x }"`

    if [[ $LANG = "ja_JP.UTF-8" ]]; then
	msg="$msg $rem_h時間 $rem_m分"
    else
	msg="$rem_h:$rem_m $msg"
    fi
    
fi

winid=$(xdotool search  --onlyvisible --classname "Dunst" 2>/dev/null)
if [[ -n "$winid" ]]; then
    dunstify -C 7777
else
    dunstify -t 5000 -i ${icon_bat} -r 7777 -u normal \
	     "$msg_title: $capacity%" "$msg"
fi
