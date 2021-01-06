#!/bin/bash

while ! pgrep -u $UID -x pulseaudio >/dev/null; do sleep 1; done
pulseaudio-control --color-muted 556060 --icons-volume " , " --icon-muted " "  --format '$VOL_ICON $VOL_LEVEL%' listen
