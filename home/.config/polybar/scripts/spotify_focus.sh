#!/bin/bash

if [ ! -e /tmp/spotify_focus_back ]; then
    xdotool get_desktop > /tmp/spotify_focus_back
    xdotool set_desktop $(xdotool get_desktop_for_window $(xdotool search --classname Spotify | sed -n 2p))
else
    xdotool set_desktop $(cat /tmp/spotify_focus_back)
    rm /tmp/spotify_focus_back
fi
