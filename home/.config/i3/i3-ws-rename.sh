#!/bin/bash

declare -A icon=(
    ['Chromium']='' ['Termite']='' ['Emacs']='ﱦ' ['Thunar']='' ['Org.gnome.Nautilus']=''
    ['Gimp-2.10']='' ['Galculator']='' ['Tlp-UI']='拉' ['calibre']=''
    ['Spotify']='阮' ['Audacious']='' ['Blueman-manager']='' ['Fcitx-config-gtk3']=''
    ['Baobab']='' ['Catfish']='' ['discord']='ﭮ' ['GParted']=''
    ['libreoffice-writer']='' ['libreoffice-calc']='' ['libreoffice-impress']='' ['libreoffice-startcenter']=''
    ['Leafpad']='' ['Viewnior']='' ['Xarchiver']='' ['mpv']='蘆'
    ['Evince']='' ['zoom']='' ['Easytag']='炙' ['Steam']='戮'
    ['Enpass']='' ['Pamac-manager']='' ['Mpdevil']=''
    ['firefox']='' ['Slack']='聆' ['Code']=''
    
    ['_EMPTY_']='ﱤ'
    ['_OTHER_']='ﬓ'
)

function rename_ws {
    local desktop=$1
    local ws_name=$(echo "$2" | sed -n $(( desktop + 1))p)
    local icons=''
    local ws_name_num=$(echo "${ws_name}" | sed -e 's/^\([0-9]\+\).*/\1/')
    local ws_name_new
    local flag_empty=false
    
    while read -r classname; do
	[ -n "$icons" ] && icons+=' '
	if [ -n "${icon[$classname]}" ]; then
	    icons+=${icon[$classname]}
	else
	    icons+=${icon['_OTHER_']}
	fi
    done < <(xdotool search --desktop $desktop --classname ".*" | \
		 xargs -l -I%% xprop -id %% WM_CLASS | cut -d" " -f4- | sed -e 's/"//g')
    
    if [[ -z "${icons}" ]]; then
	icons=${icon['_EMPTY_']}
	flag_empty=true
    fi
    
    ws_name_new="${ws_name_num}:${icons}"

    if [[ "${ws_name}" != "${ws_name_new}" ]]; then
		i3-msg "rename workspace \"${ws_name}\" to \"${ws_name_new}\"" >/dev/null 2>/dev/null
		# echo "R: rename workspace \"${ws_name}\" to \"${ws_name_new}\"" >&2
    fi

    echo ${flag_empty}
}

function fix_ws_nums {
    local ws=$1
    local desktops_num=`xdotool get_num_desktops`
    local ws_names="$2"
    local ws_name_num; local ws_name_new; local ws_name

    i=$ws
    while read -r ws_name; do
    	ws_name_new=$(echo "${ws_name}" | sed -e "s/^.*:/${i}:/")
    	if [[ "${ws_name}" != "${ws_name_new}" ]]; then
    	    i3-msg "rename workspace \"${ws_name}\" to \"${ws_name_new}\"" >/dev/null 2>/dev/null
    	    # echo "F: rename workspace \"${ws_name}\" to \"${ws_name_new}\"" >&2
    	fi
    	i=$(( i + 1 )) 
    done < <(echo "${ws_names}" | awk "NR>=${ws} {print}")
	
}

function error {
    echo "$(basename $0): $1" >&2
    exit 1
}


function __main__ {
    getopts rflh OPT

    case $OPT in
	r)
	    # echo "CALLED: $0 -r $2" >&2
	    ws=$2
	    desktop=$(expr "${ws}" - 1 2>&1)
	    if [ $? -lt 2 ]; then
		desktops_num=`xdotool get_num_desktops`
		ws_names=$(xprop -root _NET_DESKTOP_NAMES| cut -d" " -f3- | sed -e 's/, /\n/g' -e 's/"//g')
		if [[ $desktop -ge 0 ]] && [[ $desktop -lt $desktops_num ]]; then
		    rename_ws $desktop "${ws_names}"
		else
		    error "Invalid workspace number: $ws"
		fi
		
	    else
		error "Not a numeric argument."
	    fi  
	    ;;
	
	f)
	    # echo "CALLED: $0 -f $2" >&2
	    ws=$2
	    expr "${ws}" - 1 > /dev/null 2>&1
	    if [ $? -lt 2 ]; then
		desktops_num=`xdotool get_num_desktops`
		ws_names=$(xprop -root _NET_DESKTOP_NAMES| cut -d" " -f3- | sed -e 's/, /\n/g' -e 's/"//g')
		if [[ $ws -ge 0 ]] && [[ $ws -le $desktops_num ]]; then
		    fix_ws_nums $ws "${ws_names}"
		else
		    error "Invalid workspace number: $ws"
		fi
	    else
		error "Not a numeric argument."
	    fi
	    ;;
	
	l)
	    desktop_before=0
	    local flag_empty=false
	    clients_before=$(xprop -root _NET_CLIENT_LIST| cut -d" " -f5- | sed -e 's/, /\n/g')
	    
	    while read -r line; do
		
		ws_names=$(xprop -root _NET_DESKTOP_NAMES| cut -d" " -f3- | sed -e 's/, /\n/g' -e 's/"//g')
		desktop=`xdotool get_desktop`
		
		if [[ "${line}" =~ ^_NET_CURRENT_DESKTOP.* ]] || ${flag_empty}; then
		    # echo "Changed Desktop: $desktop_before -> $desktop" >&2
		    fix_ws_nums $(( desktop_before + 1 )) "${ws_names}"
		    desktop_before=$desktop
		    flag_empty=false
		fi

		if [[ "${line}" =~ ^_NET_CLIENT_LIST.* ]]; then
		    flag_empty=$(rename_ws ${desktop} "${ws_names}")
		fi
		
	    done < <(xprop -spy -root _NET_CURRENT_DESKTOP _NET_CLIENT_LIST)
	    
	    ;;

	h )
	    echo "Usage: $(basename $0) [-r WORKSPACE] [-f WORKSPACE] [-l] [-h]"
	    echo
	    echo -e "  -r WORKSPACE\t Put the icons on the workspace with the specified number"
	    echo -e "  -f WORKSPACE\t Fix desktop numbers after the specified number"
	    echo -e "  -l \t\t Start a loop process to rename workspaces"
	    echo -e "  -h \t\t Display this help and exit"
	    ;;
	* )
	    echo "$(basename $0): Invalid option."
	    echo "Try -h for more information."
	    exit 1
	    ;;
    esac
}

__main__ $@
