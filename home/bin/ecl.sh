#!/bin/bash

ROFI=~/bin/rofi_launch.sh

function _help
{
    echo -e "Usage: $(basename $0) [OPTIONS] FILE..."
    echo -e "Exec emacsclient with an existing frame focused."
    echo
    echo -e "Options:"
    echo -e "  --help, -h \t\t display this help"
    echo
    echo -e "When without options or only a file arg given:"
    echo
    echo -e "  In Terminal (without X): Start a session normally in terminal."
    echo
    echo -e "  In X sessions:"
    echo -e "    When there is no current frames, start a session with a new frame."
    echo -e "    When any frames found, start a session with an existing frame."
    echo
    exit
}

### メイン処理はここから ###

if [[ -n "$DISPLAY" ]];  then
    is_winsys=true
else
    is_winsys=false
    [[ $TERM =~ .*-256color$ ]] && export TERM=xterm-256color
fi

OPT_LIST=(
    "version"
    "help"
    "tty"
    "create-frame"
    "eval"
    "no-wait"
    "nw"
    "tty"
    "quiet"
    "suppress-output"
    "frame-parameters:"
    "display:"
    "parent-id:"
    "socket-name:"
    "server-file:"
    "alternate-editor:"
    "tramp:"
)

opt=""
is_frame_assigned=false
no_wait=false

opt_tmp=$(getopt -a \
		 -o 'VvHhtcFfenqud:s:f:a:T:' \
		 -l "$(printf "%s," "${OPT_LIST[@]}")" \
		 -- "$@") || exit 1
eval set --$opt_tmp

while [ $# -gt 0 ]; do
    case "$1" in
	--) 
	    shift
	    break
	    ;;
	-h | --help)
	    _help
	    exit
	    ;;
	-c | --create-frame)
	    is_frame_assigned=true
	    ;;
	-n | --no-wait)
	    no_wait=true
	    ;;
	-t | --nw | --tty)
	    is_winsys=false
	    is_frame_assigned=true
	    ;;	
    esac

    [[ -n "$opt" ]] && opt+=' '
    opt+="$1"
    shift
done

#pgrep -u $UID -x emacs >/dev/null 2>/dev/null
#if [ ! $? -eq 0 ] && $is_winsys; then
#    $ROFI -e "Launching Emacs..." -width 18 &
#fi

if ! $is_frame_assigned; then
    
    if $is_winsys; then
	# winid_scratchpad=$(xdotool search --title "^emacs-scratchpad$" 2>/dev/null)
	winid=""
	desktop=-1
	
	while read -r line; do
	    desktop=$(xdotool get_desktop_for_window $line 2>/dev/null)
	    if [[ $desktop -ge 0 ]]; then
		winid=$line
		break
	    fi	
	done < <(xdotool search --classname "emacs" 2>/dev/null)
	## | sed -e "/^${winid_scratchpad}$/d")
	
	if [[ -n "$winid" ]]; then
	    if [[ -n "$@" ]] && ! $no_wait; then
		winid_parent=$(xdotool getactivewindow 2>/dev/null)
		echo "parent: $winid_parent"
	    fi
	    xdotool set_desktop $desktop
	    xdotool windowactivate $winid
	    
	    if [[ -z $@ ]]; then
		exit
	    else
		emacsclient -e -q "(setq frame-prev (selected-frame))"
		bufname_prev=$(emacsclient -e '(with-selected-frame (selected-frame) (with-current-buffer (window-buffer (selected-window)) (buffer-name)))' \
				   | sed -e 's/^"//' -e 's/"$//')
	    fi
	    
	else
	    [[ -n "$opt" ]] && opt+=' '
	    opt+="-c --display=$DISPLAY"
	    [[ -z $@ ]] && opt+=" --no-wait"
	fi
	
    else
	[[ -n "$opt" ]] && opt+=' '
	opt+="-t"
    fi
    
fi

if [[ -n "$@" ]]; then
    for arg in "$@"; do
	opt+=" \"${arg}\""
    done
    # else
    #     opt+=" -e '(switch-to-buffer \"*scratch*\")'"
fi

eval "emacsclient -a '' $opt"
#killall -q rofi

if [[ -n "$winid_parent" ]]; then
    desktop=$(xdotool get_desktop_for_window $winid_parent 2>/dev/null)
    if [[ $desktop -ge 0 ]]; then
	xdotool set_desktop $desktop
	xdotool windowactivate $winid_parent
	[[ -n "${bufname_prev}" ]] && \
	    emacsclient -n -e "(with-selected-frame frame-prev (with-current-buffer (window-buffer (selected-window)) (switch-to-buffer \"${bufname_prev}\")))"
    fi
fi


