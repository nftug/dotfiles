#!/bin/bash

BAT_TOOLTIP="`dirname $0`/bat_tooltip.sh"

icon_discharging=("" "" "" "" "" "" "" "" "" "" "")
icon_charging=("" "" "" "" "" "" "" "" "" "" "")
tmpfile_notice=/tmp/batnotify.tmp
thresholds_capacity=(5 10 15 20 25)

capacity_full=95

declare list_bat=(
    'max170xx_battery'
    'BAT0'
    false
)

for i in "${!list_bat[@]}"; do
    if [[ -e /sys/class/power_supply/${list_bat[$i]} ]]; then
	BAT=${list_bat[$i]}
	break
    elif [[ $i -eq $(( ${#list_bat[@]} - 1)) ]]; then
	exit 1
    fi
done

capacity=$(cat /sys/class/power_supply/$BAT/capacity)
status=$(cat /sys/class/power_supply/$BAT/status)

[ ! -f ${tmpfile_notice} ] && touch ${tmpfile_notice}

ul_color="81A1C1"
ifnotify=false

if [[ ${status} = "Discharging" ]]; then
    # アイコンの選択
    if [[ ${capacity} -ge 90 ]]; then
	icon=${icon_discharging[10]}
    else
	icon=${icon_discharging[$(( capacity / 10 ))]}
	if [[ ${capacity} -le ${thresholds_capacity[-1]} ]] && [[ ${capacity} -gt ${thresholds_capacity[-3]} ]]; then
	    ul_color="C9BC0E"
	    label_color="C9BC0E"
	elif [[ ${capacity} -le ${thresholds_capacity[-3]} ]]; then
	    ul_color="FF5252"
	    label_color="FF5252"
	fi
    fi
    
    sp='%{T4} %{T-}'

    # 通知
    if [[ ${capacity} -le ${thresholds_capacity[-1]} ]]; then
	if [ -s ${tmpfile_notice} ]; then
	    source ${tmpfile_notice}
	    
	    for threshold in "${thresholds_capacity[@]}"; do
		[[ ${capacity} -le ${threshold} ]] && break
		# capacity=16のときは、threshold=20
		# capacity=20のときは、threshold=20
	    done

	    # 以前に通知済みでない、または以前の充電状態と異なるなら、通知する。
	    if [[ ${prev_capacity} -gt ${threshold} ]] || [[ ${prev_status} != ${status} ]]; then
		ifnotify=true
	    fi
	    
	else
	    ifnotify=true
	fi
    fi
else
    ul_color="4db6ac"
    source ${tmpfile_notice}

    if [[ ${prev_status} != ${status} ]]; then
	eval $BAT_TOOLTIP
    fi
    
    if [[ ${capacity} -ge ${capacity_full} ]]; then
	icon=${icon_charging[10]}
	label_color="4db6ac"
	
	# 以前に通知済みでなければ、通知する。
	[[ ${prev_capacity} -lt ${capacity_full} ]] && ifnotify=true
    else
	icon=${icon_charging[$(( ${capacity} / 10 ))]}
    fi

    sp=' '
fi

echo "prev_capacity=${capacity}" > ${tmpfile_notice}
echo "prev_status=${status}" >> ${tmpfile_notice}

# ここにパネル表示処理
[[ -n ${label_color} ]] && icon="%{F#$label_color}${icon}"
# echo "%{u#$ul_color}%{+u} %{T3}${icon}${sp}%{T-}${capacity}% "
echo "%{T3}${icon}${sp}%{T-}${capacity}%"

if ${ifnotify}; then
    if [[ ${capacity} -ge ${capacity_full} ]]; then
	if [[ $LANG = "ja_JP.UTF-8" ]]; then
	    alert_arg=(dialog-information
		       "バッテリー充電の完了 (${capacity}%)"
		       "コンピュータからACアダプタを抜いてください。")
	else
	    alert_arg=(dialog-information
		       "Battery Charged (${capacity}%)"
		       "Pull out the AC from the computer.")
	fi
	cmd=""
	
    elif [[ ${capacity} -gt ${thresholds_capacity[2]} ]]; then
	if [[ $LANG = "ja_JP.UTF-8" ]]; then
	    alert_arg=(dialog-warning
		       "バッテリー残量が低下しています (${capacity}%)"
		       "ACアダプタを接続してください。")
	else
	    alert_arg=(dialog-warning
		       "Battery Low (${capacity}%)"
		       "Plug in to AC or suspend immediately.")
	fi
	#cmd="light -S 30"
	cmd=""
    elif [[ ${capacity} -gt ${thresholds_capacity[0]} ]]; then
	if [[ $LANG = "ja_JP.UTF-8" ]]; then
	    alert_arg=(dialog-error
		       "バッテリー残量が危険な状態です！ (${capacity}%)"
		       "まもなく自動的にサスペンド状態へ移行します。\nACアダプタを接続してください。")
	else
	    alert_arg=(dialog-error
		       "Battery Critical (${capacity}%)"
		       "The computer will be suspended automatically soon.\nPlug in to AC or suspend immediately.")
	fi
	#cmd="light -S 25"
	cmd=""
    else
	if [[ $LANG = "ja_JP.UTF-8" ]]; then
	    alert_arg=(dialog-error
		       "バッテリー残量が危険な状態です！ (${capacity}%)"
		       "コンピュータはサスペンド状態へ移行します。")
	    cmd="zenity --warning --no-wrap  --timeout 10 \
	   	    --text \"バッテリー残量が危険な状態です。\\n10秒後にサスペンド状態へ移行します。\" \
		    ; systemctl suspend -i"
	else
	    alert_arg=(dialog-error
		       "Battery Critical (${capacity}%)"
		       "The computer will be suspended automatically.")
	    cmd="zenity --warning --no-wrap  --timeout 10 \
	   	    --text \"Battery state is critical.\\nThe computer will be suspended in 10 seconds.\" \
		    ; systemctl suspend -i"
	fi
    fi

    dunstify -r 7777 -u normal -t 20000 -i "${alert_arg[0]}" "${alert_arg[1]}" "${alert_arg[2]}"
    eval "${cmd}"
fi
