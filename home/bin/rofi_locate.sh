#!/bin/bash

ROFI_CMD=~/bin/rofi_launch.sh

xdg-open "$(locate $HOME | $ROFI_CMD -0 -dmenu -threads 0 -i -p "locate")"
