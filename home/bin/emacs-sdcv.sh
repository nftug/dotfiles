#!/bin/bash

__get_resolution() {
    # neofetchのソースから拝借
    local resolution
    resolution="$(xrandr --nograb --current |\
    			 awk -F 'connected |\\+|\\(' \
			 '/ connected/ && $2 {printf $2 ", "}')"
    resolution="${resolution/primary }"
    resolution="${resolution%,*}"
    w=${resolution%x*}
    h=${resolution#*x}
}


clipstr=$(xsel -o -c)
cmd="${1#-}"

title_popup="emacs-sdcv-popup"
title_normal="emacs-sdcv"

if [[ ${cmd} = 'c' ]]; then
    if [ -n "$clipstr" ]; then
	arg="\"$clipstr\""
    else
	echo "Nothing selected" >&2
    fi
elif [ -n "$1" ]; then
    arg="\"$1\""
else
    arg=""
fi

if [ -n "${arg}" ]; then
    xdotool search --name --onlyvisible "^${title_normal}$" windowactivate >/dev/null 2>/dev/null
    if [ $? -eq 0 ]; then
	emacsclient -e "(sdcv-search-detail ${arg})"
    else
	
	eval $(xdotool getmouselocation --shell)
	mouse_x=$X; mouse_y=$Y
	
	(emacsclient -c -a "" -F "((name . \"${title_popup}\") (top . $(( mouse_y + 10 ))) (left . $(( mouse_x + 10 ))) (height . 16) (width . 50) (cursor-type . nil) (undecorated . t))" -e "(sdcv-popup ${arg})" >/dev/null 2>/dev/null) &

	WINID=$(xdotool search --sync --name "^${title_popup}$")
	xdotool windowactivate $WINID
	eval $(xdotool getwindowgeometry --shell $WINID)
	LEFT=$X; TOP=$Y;
	width_popup=$WIDTH; height_popup=$HEIGHT
	
	__get_resolution
	
	if [[ $mouse_x -gt $(( w - width_popup - 10 )) ]]; then
	    LEFT=$(( w - width_popup - 10 ))
	fi
	if [[ $mouse_y -gt $(( h - height_popup - 10 )) ]]; then
	    TOP=$(( h - height_popup - 10 ))
	fi

	xdotool windowmove $WINID $LEFT $TOP

	while true; do
	    sleep 1
	    winname_active=$(xdotool getactivewindow getwindowname)

	    eval $(xdotool getmouselocation --shell)
	    X_diff=$(( LEFT - X ))
	    Y_diff=$(( TOP - Y ))
	    if [[ $X_diff -gt 100 ]] || [[ $Y_diff -gt 100 ]] \
		   || [[ $X -gt $(( LEFT + WIDTH )) ]] || [[ $Y -gt $(( TOP + HEIGHT )) ]] \
		   || [[ "${winname_active}" != "${title_popup}" ]]; then
		break
	    fi
	done

	xdotool search --name --onlyvisible "^${title_popup}$"  >/dev/null 2>/dev/null
	if [ $? -eq 0 ]; then
	    eval $(xdotool getmouselocation --shell)
	    emacsclient -e "(delete-frame (select-frame-by-name \"${title_popup}\"))"
	    xdotool mousemove $X $Y
	fi
    fi
else
    eval $(xdotool getmouselocation --shell)
    xdotool search --name --onlyvisible "^${title_normal}$"
    if [ ! $? -eq 0 ]; then
	eval $(xdotool search --classname "Polybar" getwindowgeometry --shell)
	height_bar=$HEIGHT

	emacsclient -c -a "" -F "((name . \"${title_normal}\") (top . $(( height_bar + 15 )) ) (left . -15) (height . 20) (width . 60))" -e "(sdcv-popup)" >/dev/null 2>/dev/null
	
	#WINID=$(xdotool search --sync --name "^${title_normal}$")	
	#xdotool windowactivate $WINID
	
    else
	emacsclient -e "(delete-frame (select-frame-by-name \"${title_normal}\"))"
    fi
    xdotool mousemove $X $Y
fi
