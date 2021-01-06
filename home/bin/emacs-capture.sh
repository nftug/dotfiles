#!/bin/bash

CLASSNAME_BROWSER=Chromium

clipstr=$(xsel -o -c | sed 's/&/and/g' | sed 's/"/\\"/g')

echo "clip: $clipstr"

if [[ "$1" =~ ^org-protocol:// ]]; then
    arg="$1"
elif [[ "$1" =~ ^https?:// ]]; then
    url=$(echo "$1" | sed 's/&/\\&/g' | sed 's/"/\\"/g')
fi

if [[ -z "${arg}" ]]; then
    cmd="${1#-}"

    # アクティブウィンドウがブラウザのクラス名を持つか確認    
    winid=$(xdotool getactivewindow)
    classname=$(xprop -id ${winid} WM_CLASS | cut -d" " -f4- | sed -e 's/"//g')
    
    if [[ -n "${url}" ]] || [[ ${classname} = ${CLASSNAME_BROWSER} ]]; then
	title=$(xdotool getwindowname ${winid} |\
		    sed -e "s/\(.\+\) - .*$/\1/" -e 's/&/and/g' -e 's/"/\\"/g')

	# URLの取得
	if [[ -z "${url}" ]]; then
	    xdotool windowactivate --sync ${winid} key ctrl+l ctrl+c
	    sleep 0.5
	    url=$(xsel -o -c | sed 's/&/\\&/g' | sed 's/"/\\"/g')
	fi
	
	if [ -n "$clipstr" ] ; then
	    arg="org-protocol://capture?template=p&title=${title}&url=${url}&body=${clipstr}"
	else
	    arg="org-protocol://capture?template=L&title=${title}&url=${url}"
	fi
    else
	if [ -n "$clipstr" ]; then
	    url=$(xdotool getwindowname ${winid} |\
		      sed -e "s/\(.\+\) - .*$/\1/" -e 's/&/and/g' -e 's/"/\\"/g')
	    if [[ $cmd = 'n' ]]; then
		arg="org-protocol://capture?template=q&url=${url}&body=${clipstr}"
	    else
		arg="org-protocol://capture?template=${cmd}&url=${url}&body=${clipstr}"
	    fi
	else
	    arg="org-protocol://capture?template=${cmd}"
	fi
    fi
fi

emacsclient -nc -F "((name . \"emacs-capture\") (height . 15) (width . 90))" "${arg}"
xdotool search --name --onlyvisible "^emacs-capture$" windowactivate
