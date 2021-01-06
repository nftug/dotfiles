#!/bin/bash

I3_WS_RENAME=~/.config/i3/i3-ws-rename.sh

exec_restart () {
    BASENAME=`basename $1`
    killall -q "$BASENAME"
    while pgrep -u $UID -x "$BASENAME" >/dev/null; do sleep 1; done
    eval $@
}

launch_polybar () {
    pkill -fx "polybar --reload $1"
    while pgrep -fx "polybar --reload $1" >/dev/null; do sleep 1; done
    
    for m in $(polybar --list-monitors | cut -d":" -f1); do
	MONITOR=$m polybar --reload $1 &
    done
    
    # ln -s /tmp/polybar_mqueue.$! /tmp/ipc-bottom 2>/dev/null
    # echo message >/tmp/ipc-bottom
}


if [[ $DISPLAY != ":0" ]]; then
    launch_polybar main-gpd &
else

    ~/.config/i3/stalonetray-scratch.sh start &

    exec_restart $I3_WS_RENAME -l &
    launch_polybar main-$HOSTNAME &
    ~/bin/launch_picom.py &
    exec_restart dunst &

fi
