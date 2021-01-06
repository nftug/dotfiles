#!/bin/sh

# i3-volumeを動作させるため、言語を英語に変更。
export LANG=C

#TMP_PREV_SINK=/tmp/i3-vol-sink
default_opts="-N dunstify"

while ! pgrep -u $UID -x pulseaudio >/dev/null; do sleep 1; done
#sinkname=$(pacmd list-sinks 2> /dev/null | awk -F "[<>]" '/^\s+name: <.*>/{print $2}'|sed -n '$p')
sinkname=$(i3-volume output "%s")

if [[ $1 = "listen" ]]; then
    while [ -z "${sinkname}" ]; do
	# echo -e "%{F#555}%{u#555}%{+u}INIT...%{F-}"
	echo -e "%{F#556066}INIT...%{F-}"
	sinkname=$(i3-volume output "%s")
	sleep 1
    done

    i3-volume -s ${sinkname} listen "$2" 2> /dev/null \
	| (while true; do
	       read -r line
	       if [[ ${line} =~ (.*MUTE) ]] ||  [[ ${line} =~ ﱝ ]]; then
		   # line="%{F#555}%{u#555}%{+u}$line"
		   line="%{F#556066}$line"
	       else
		   # line="%{u#81A1C1}%{+u}$line"
		   line="$line"
	       fi	       
	       echo -e "$line" | sed 's/MUTE/0%/'
	   done)
else
    if [[ $@ =~ (up) ]] || [[ $@ =~ (down) ]]; then
        vol=`i3-volume -s ${sinkname} output %v`
    	if [[ ${vol} = 'MUTE' ]]; then
    	    i3-volume -s ${sinkname} mute
    	    exit
    	fi
    fi
    
    NO_NOTIFY_COLOR=1 i3-volume -s ${sinkname} "$default_opts" "$@"
fi


