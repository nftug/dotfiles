#!/bin/bash

title_scratchpad="stalonetray"
timelimit=0

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

if [[ $1 = "start" ]]; then
    new=true
    show=false
else
    new=false
    show=true

    xdotool search --class "${title_scratchpad}" >/dev/null 2>/dev/null
    if [ ! $? -eq 0 ]; then
	new=true
    fi
fi

if $new; then
    killall -q stalonetray
    while pgrep -u $UID -x stalonetray >/dev/null; do sleep 1; done
    stalonetray &
fi

if $show; then
    WINID=`xdotool search --sync --name "^${title_scratchpad}$" 2>/dev/null`
    i3-msg "[title=\"^${title_scratchpad}$\"] scratchpad show" >/dev/null 2>/dev/null

    __get_resolution

    eval $(xdotool getwindowgeometry --shell $WINID)
    width_scratchpad=$WIDTH
    
    eval $(xdotool search --classname "Polybar" getwindowgeometry --shell)
    height_bar=$HEIGHT

    xdotool windowmove $WINID $(( w - width_scratchpad - 10 )) $(( 10 + height_bar ))
    
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
xdotool search --class --onlyvisible "^${title_scratchpad}$" >/dev/null 2>/dev/null
[ $? -eq 0 ] && i3-msg "[title=\"^${title_scratchpad}$\"] scratchpad show" >/dev/null 2>/dev/null
