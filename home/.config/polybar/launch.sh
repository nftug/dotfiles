#!/bin/bash

# Terminate already running bar instances
killall -q polybar

# Wait until the processes have been shut down
while pgrep -u $UID -x polybar >/dev/null; do sleep 1; done

# Launch bar
polybar main &

#symlink spotify config
ln -s /tmp/polybar_mqueue.$! /tmp/ipc-bottom
echo message >/tmp/ipc-bottom

echo "Bars launched..."
