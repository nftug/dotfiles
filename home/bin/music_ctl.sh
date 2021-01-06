#!/bin/bash

if [ ! -z `pgrep -fo deadbeef` ]; then
    if [[ $1 = "--play-pause" ]]; then
	deadbeef --play-pause
    elif [[ $1 = "--prev" ]]; then
	deadbeef --prev
    elif [[ $1 = "--next" ]]; then
	deadbeef --next
    elif [[ $1 = "--stop" ]]; then
	deadbeef --stop
    fi
elif [ ! -z `pgrep -fo spotify` ]; then
    if [[ $1 = "--play-pause" ]]; then
	dbus-send --print-reply --dest=org.mpris.MediaPlayer2.spotify /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.PlayPause
    elif [[ $1 = "--prev" ]]; then
	dbus-send --print-reply --dest=org.mpris.MediaPlayer2.spotify /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.Previous
    elif [[ $1 = "--next" ]]; then
	dbus-send --print-reply --dest=org.mpris.MediaPlayer2.spotify /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.Next
    elif [[ $1 = "--stop" ]]; then
	dbus-send --print-reply --dest=org.mpris.MediaPlayer2.spotify /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.Stop
    fi
else
    if [[ $1 = "--play-pause" ]]; then
	mpc toggle
    elif [[ $1 = "--prev" ]]; then
	mpc stop
	mpc prev
	mpc play
    elif [[ $1 = "--next" ]]; then
	mpc stop
	mpc next
	mpc play
    elif [[ $1 = "--stop" ]]; then
	mpc stop
    fi
fi
