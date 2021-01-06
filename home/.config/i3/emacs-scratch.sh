#!/bin/bash

title_scratchpad="emacs-scratchpad"
timelimit=2

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

### メイン処理はここから ###

if [[ $1 = "start" ]]; then
    new=true
    show=false
else
    new=false
    show=true
    
    xdotool search --name "^${title_scratchpad}$" >/dev/null 2>/dev/null
    if [ ! $? -eq 0 ]; then
	new=true
    fi
fi

if $new; then
    emacsclient -a "" -n -c -F "((name . \"${title_scratchpad}\"))" -e '(switch-to-buffer "*scratch*")'
else
    emacsclient -n -e "
        (dolist (frame (frame-list))
        	(with-selected-frame frame
    		(if (equal \"${title_scratchpad}\" (frame-parameter frame 'name))
	    	      (switch-to-buffer \"*scratch*\"))))
		   "
fi

if $show; then
    WINID=`xdotool search --sync --name "^${title_scratchpad}$" 2>/dev/null`
    i3-msg "[title=\"^${title_scratchpad}$\"] scratchpad show" >/dev/null 2>/dev/null
    
    eval $(xdotool getwindowgeometry --shell $WINID)
    width_scratchpad=$WIDTH

    __get_resolution

    eval $(xdotool search --classname "Polybar" getwindowgeometry --shell)
    height_bar=$HEIGHT
    
    xdotool windowmove $WINID $(( ( w - width_scratchpad ) / 2 )) $(( 15 + height_bar ))
    
    countflag=false
    timeleft=${timelimit}
    while true; do     # 1秒ずつアクティブ状態を確認
	if ! $countflag; then    # カウントダウンなしの場合 (通常時)
	    winname_active=$(xdotool getactivewindow getwindowname)
	    if [[ ${winname_active} != ${title_scratchpad} ]]; then
		# 非アクティブになってから $timeout 秒までカウントダウン開始。
		countflag=true
	    fi
	else   # カウントダウン中の場合
	    winname_active=$(xdotool getactivewindow getwindowname)
	    if [[ ${winname_active} = ${title_scratchpad} ]]; then
		# アクティブなウィンドウが合致したら、カウントダウンをやめてリセット
		countflag=false
		timeleft=${timelimit}
	    else
		# 合致しなければカウントダウン。時間が来たら終了処理へ抜ける
		timeleft=$(( ${timeleft} - 1 ))
		[ ${timeleft} -lt 0 ] && break
	    fi
	fi
	sleep 1 
    done
fi

# ウィンドウが存在するときだけ、トグル操作で隠す
xdotool search --name --onlyvisible "^${title_scratchpad}$" >/dev/null 2>/dev/null
[ $? -eq 0 ] && i3-msg "[title=\"^${title_scratchpad}$\"] scratchpad show"
