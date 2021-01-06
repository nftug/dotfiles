#!/bin/sh

export LANG=C

if [ ! -f ~/bin/dropbox.py ]; then
    echo "Cannot find dropbox.py" >&2
    exit 1
fi


if [[ $1 = "toggle" ]]; then
    pgrep -u $UID -x dropbox
    if [ $? -eq 0 ]; then
	~/bin/dropbox.py stop
    else
	~/bin/dropbox.py start
    fi
else
    status=$(~/bin/dropbox.py status)
    echo -n "%{T-} %{T4}"
    case $status in
	"Up to date" | "最新の状態" ) echo -n "﫟" ;;
	Syncing* | *同期中*  ) echo -n "痢" ;;
	"Starting..." | "開始中..." | \[.*\]* ) echo -n "" ;;
	"Connecting..." | "接続中..." ) echo -n "" ;;
	Dropbox*! ) echo -n "" ;;
	* ) echo -n $status ;;
    esac
    echo " %{T-}"
fi
