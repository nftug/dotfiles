#!/bin/bash

activewin=`xdotool getactivewindow`
pid=`xdotool getwindowpid $activewin`
progname=`basename $(ps $pid|awk 'NR==2 {print $5}')`

wintitle=$(xdotool getwindowname $activewin)

sleep 0.1

if [[ ${wintitle} =~ -scratchpad$ ]]; then
    socket=`i3 --get-socketpath`
    i3-msg -s ${socket} [title="^${wintitle}$"] move scratchpad
    
elif [[ ${wintitle} =~ tmux$ ]]; then
    xdotool key ctrl+b x
    
else
    case $progname in
	"chromium"|"nautilus"|"gedit"|"thunar" )
	    xdotool key ctrl+w ;;
	gimp-* )
            winname=`xdotool getwindowname $activewin`
	    if [ -n "$(echo $winname|grep 'GIMP$')" ]; then
		xdotool key ctrl+w
	    else
		xdotool key Alt+F4
	    fi
	    ;;
	"emacs" )
	    # wintitle=$(xdotool getwindowname $activewin)
	    # if [[ $wintitle = "emacs-scratchpad" ]] || [[ $wintitle = "emacs-capture" ]]; then
	    #     xdotool key Alt+F4
	    # else
	    buflist=$(emacsclient --eval '(with-current-buffer (window-buffer (selected-window)) (buffer-list))' \
			  | awk -F'#<buffer *|> ' '{for (i=1; i<=NF; i++) if ($i != "" && $i !="(") {print $i}}' \
			  | grep -v '\*')
	    if [ -n "$buflist" ]; then
		#xdotool key ctrl+x && sleep 0.1 && xdotool key k
		emacsclient -e "(with-selected-frame (selected-frame) (with-selected-window (selected-window) (let ((last-nonmenu-event nil))(kill-this-buffer))))"
	    else
		xdotool key Alt+F4
	    fi
	    # fi
	    ;;
	"tilda"|"gnome-terminal"|"termite" )
	    xdotool key Ctrl+d ;;
	* )
	    xdotool key Alt+F4 ;;
    esac
fi

exit 0

    
