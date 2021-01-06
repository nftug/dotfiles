#!/bin/bash

PASSWDFILE=$HOME/.vnc/passwd

if [[ -z "$1" ]]; then
    echo "Usage: $(basename $0) ORIENTATION DISPLAY_NUMBER"
    exit 1
fi

ORI=$1
if [[ -n "$2" ]]; then
    NUM=$2
else
    NUM=1
fi

pgrep -u $UID -f 'Xvnc :$NUM'
if [ ! $? -eq 0 ]; then
    unset I3SOCK
    # unset SESSION_MANAGER
    # unset DBUS_SESSION_BUS_ADDRESS
    vncserver :$NUM &
fi

sleep 1
vncconfig -display :$NUM -set BlacklistTimeout=0 -set BlacklistThreshold=1000000

x2vnc -shared -$ORI -passwdfile $PASSWDFILE -noreconnect localhost:$NUM
