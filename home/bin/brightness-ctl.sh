#!/bin/bash

# https://gist.github.com/Blaradox/030f06d165a82583ae817ee954438f2e

function get_brightness {
  light -G | cut -d '.' -f 1
}

function send_notification {
  icon="notification-display-brightness-medium"
  brightness=$(get_brightness)
  # Make the bar with the special character ─ (it's not dash -)
  # https://en.wikipedia.org/wiki/Box-drawing_character
  bar=$(seq -s "─" 0 $((brightness / 5)) | sed 's/[0-9]//g')
  # Send the notification
  dunstify -t 500 -i "$icon" -r 5555 -u normal "${brightness}%    $bar"
}

case $1 in
  up)
    # increase the backlight by 5%
    light -A 2
    send_notification
    ;;
  down)
    # decrease the backlight by 5%
    light -U 2
    send_notification
    ;;
esac
