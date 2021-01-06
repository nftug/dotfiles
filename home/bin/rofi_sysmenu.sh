#!/bin/bash

ROFI_CMD=~/bin/rofi_launch.sh
timeout=60

if [ "$1" = "show" ]; then
    $ROFI_CMD -no-sidebar \
	      -modi ' :~/bin/rofi_sysmenu.sh' -show ' ' \
	      -width -25 -lines 6
else
    list=(
	"Shutdown" "system-shutdown"  "$HOME/.config/i3/i3-exit.sh shutdown"
        "Reboot" "system-reboot"      "$HOME/.config/i3/i3-exit.sh reboot"
        "Suspend" "system-suspend"    "systemctl suspend -i"
	"Logout" "system-log-out"     "$HOME/.config/i3/i3-exit.sh logout"
	"Lock" "system-lock-screen"   "loginctl lock-session"
	"Cancel" "cancel"             ""
    )

    list_ja=( "シャットダウン" "再起動" "サスペンド" "ログアウト" "ロック" "キャンセル" )
    meta_ja=( "syattodaun" "saikiko" "roguauto" "sasupendo" "rokku"  "kyanseru" )
    
    for (( i=1; i<=$((${#list[@]}/3)); i++ )); do
	if [[ $LANG = "ja_JP.UTF-8" ]]; then
	    selected="${list_ja[i-1]}"
	    column="${selected}\0icon\x1f${list[$i*3-2]}\x1fmeta\x1f${list[$i*3-3]} ${meta_ja[i-1]}"
	else
	    selected="${list[$i*3-3]}"
	    column="${selected}\0icon\x1f${list[$i*3-2]}"
	fi
	
        [[ -z "$@" ]] && echo -e "${column}" &&  continue
        
      	if [[ "$@" == "${selected}" ]]; then
	    command="${list[$i*3-1]}"
	    str="${list[$i*3-3]}"
	    icon="${list[$i*3-2]}"
	    break
	fi
	    
    done

    if [ -n "$command" ]; then
	if [[ $icon = "system-lock-screen" ]] || [[ $icon = "system-suspend" ]]; then
	    eval ${command:-}
	else
	    if [[ $LANG = "ja_JP.UTF-8" ]]; then
		msg="${list_ja[$i-1]}しますか？\n(${timeout}秒後に自動的に${list_ja[$i-1]}します。)"
	    else
		msg="Proceed to ${str,,}?\n(Will automatically ${str,,} in $timeout seconds.)"
	    fi
	    killall -q rofi
	    (zenity --icon-name="${icon}" --question --no-wrap --text "${msg}" --timeout $timeout
	     [ ! $? -eq 1 ] && eval ${command:-}) &
	    sleep 0.5
	    i3-msg [class="Zenity"] sticky enable
	fi
    fi
fi


