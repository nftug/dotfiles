#!/bin/sh

URL="$1"
VIDEO_ID=`echo -n $URL | sed 's/.*v=\([^\&]*\).*/\1/'`
URL="https://www.youtube.com/watch?v=$VIDEO_ID"

playerctl -p chromium pause
mpv "$URL"
