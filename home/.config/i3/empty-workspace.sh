#!/bin/bash

#current_ws=$(i3-msg -t get_workspaces | jq -rc 'map(select(.focused==true))|map(.num)|.[]' 2> /dev/null)
#max_ws$(i3-msg -t get_workspaces | jq -rc 'map(.num)|.[]' 2> /dev/null)

desktop=$(xdotool get_desktop)
num_desktops=$(xdotool get_num_desktops)

WS_RENAME=~/.config/i3/i3-ws-rename.sh

ICON_EMPTY='ﱤ'

function move_container_to {
    n=$1

    if [[ $n -gt $num_desktops ]] || [[ $n -eq 0 ]]; then
	i3-msg move container to workspace "${n}:${ICON_EMPTY}" >/dev/null 2>/dev/null 
    else
	i3-msg move container to workspace number $n >/dev/null 2>/dev/null 
    fi

    i3-msg workspace number $n >/dev/null 2>/dev/null 

    sleep 0.2
    eval $WS_RENAME -r $(( desktop + 1 ))
    eval $WS_RENAME -f $(( desktop + 1 ))
}

getopts npNPWT OPT

case $OPT in
    n)
	if [[ $(( desktop + 1 )) -eq $num_desktops ]]; then
	    classes=$(xdotool search --desktop $desktop --classname ".*")
	    if [[ -z "${classes}" ]]; then
		xdotool set_desktop 0
	    else
		i3-msg workspace "$(( num_desktops + 1 )):${ICON_EMPTY}" >/dev/null 2>/dev/null 
	    fi
	else
	    xdotool set_desktop $(( desktop + 1 ))
	fi

	# eval $WS_RENAME -f 1
	;;
    p)
        prev_desktop=$(( desktop - 1 ))
	if [[ $prev_desktop -lt 0 ]]; then
	    i3-msg workspace "$(( num_desktops + 1 )):${ICON_EMPTY}" >/dev/null 2>/dev/null 
	else
	    xdotool set_desktop $prev_desktop
	fi

	# eval $WS_RENAME -f 1
	;;
    N)
	if [[ $(( desktop + 1 )) -eq $num_desktops ]]; then
	    num_classes=$(xdotool search --desktop $desktop --classname ".*" | wc -l)
	    if [[ ${num_classes} -eq 0 ]]; then
		exit
	    elif [[ ${num_classes} -eq 1 ]]; then
		n=1
		desktop=1
	    else	
		n=$(( num_desktops + 1 ))
	    fi
	else
	    n=$(( desktop + 2 ))
	fi

        move_container_to $n
	;;
    P)
	if [[ $desktop -eq 0 ]]; then
	    n=$(( num_desktops + 1 ))
	else
	    n=$desktop
	fi

        move_container_to $n
       	;;
    W)
	n=$2
	expr "${n}" - 1 > /dev/null 2>&1
	if [ $? -lt 2 ]; then
	    if [[ $n -gt $num_desktops ]]; then
		num_classes=$(xdotool search --desktop $desktop --classname ".*" | wc -l)
		if [[ ${num_classes} -eq 1 ]]; then
		    [[ $(( desktop + 1 )) -eq $num_desktops ]] && exit
		    
		    i3-msg move workspace "$(( num_desktops + 1 )):${ICON_EMPTY}" >/dev/null 2>/dev/null 
		    i3-msg workspace number $(( num_desktops + 1 )) >/dev/null 2>/dev/null
		    
		    eval $WS_RENAME -r $num_desktops
		    # eval $WS_RENAME -f $(( desktop + 1 ))
		    exit
		fi
		
		n=$(( num_desktops + 1 ))
	    fi

	    move_container_to $n
	else
	    exit 1
	fi
	;;
    T )
	classes=$(xdotool search --desktop $desktop --classname ".*")
	[[ -z "${classes}" ]] && [[ $(( desktop + 1 )) -eq $num_desktops ]] && \
	    exit
	# Deleted a workaround when classes are nil: xdotool set_desktop $(( desktop + 1 ))

	eval $WS_RENAME -f 1
	i3-msg workspace "$(( num_desktops + 1 )):${ICON_EMPTY}" >/dev/null 2>/dev/null 
	;;
    *)
	exit 1 ;;
esac





