#!/bin/bash

[[ ! $HOSTNAME =~ gpd ]] && exit 1

if [[ $LANG = "ja_JP.UTF-8" ]]; then
    msg="スクリーンを回転しますか？"
else
    msg="Rotate the screen?"
fi

zenity --question --no-wrap --text "${msg}" --icon-name=tablet --timeout 10
if [ $? -eq 0 ]; then   
    rotate_now=`xrandr | grep 'DSI1\|DSI-1' | awk '{print $5}'`
    [[ -z "$rotate_now" ]] && exit 1

    device_touch="Goodix Capacitive TouchScreen"

    if [[ $rotate_now = "right" ]]; then
	rotate="normal"
	touch_arg='0 0 0 0 0 0 0 0 0'
    else
	rotate="right"
	touch_arg='0 1 0 -1 0 1 0 0 1'
    fi
    xrandr -o $rotate && xinput set-prop pointer:"$device_touch" "Coordinate Transformation Matrix" $touch_arg
    nitrogen --restore
fi
