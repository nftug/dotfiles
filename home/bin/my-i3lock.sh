#!/bin/sh

pgrep -u $UID -x i3lock

if [[ ! $? -eq 0 ]]; then
    if [[ $LANG = "ja_JP.UTF-8" ]]; then
	i3lock-fancy -f 源ノ角ゴシック-JP -- scrot -z -o
    else
	export LANG=C
	i3lock-fancy -f Cantarell -- scrot -z -o
    fi
else
    exit
fi
