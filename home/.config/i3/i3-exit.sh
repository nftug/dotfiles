#!/bin/bash

# rofiを起動しているとretの戻り値が使えない。戻り値はグローバル変数で確認。
declare -i ret
declare exit_cmd

kill_emacs_server () {
    kill_cmd="(let ((last-nonmenu-event nil))(save-buffers-kill-emacs))"

    n=$(emacsclient -e '(my/modified-buffer-exist-p)')
    if [[ $n -gt 0 ]]; then	
	winid=""
	desktop=-1	
	while read -r line; do
	    desktop=$(xdotool get_desktop_for_window $line 2>/dev/null)
	    if [[ $desktop -ge 0 ]]; then
		winid=$line
		break
	    fi	
	done < <(xdotool search --classname "emacs" 2>/dev/null \
		     | sed -e "/^${winid_scratchpad}$/d")
	
	if [ $desktop -lt 0 ]; then
	    emacsclient -nc
	else
	    (xdotool windowactivate $winid) &
	fi
	
	emacsclient -e "${kill_cmd}"
	ret=$?
    else
	ret=0
    fi
}

case $1 in
    "logout" )
	exit_cmd="i3-msg exit" ;;
    "reboot" )
	exit_cmd="systemctl -i reboot" ;;
    "shutdown" )
	exit_cmd="systemctl -i poweroff" ;;
esac

pgrep -u $UID -x emacs > /dev/null
if [ $? -eq 0 ]; then
    kill_emacs_server
    if [ ! $ret -eq 0 ]; then
	# 編集中ならば処理中止。
	exit 1
    fi
fi

pkill vnc

eval "${exit_cmd}"



