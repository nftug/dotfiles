#!/bin/sh

title_scratchpad="termite-scratchpad"
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
    # OPEN_TMUX=true termite -t "${title_scratchpad}" -r pop-up &
    termite -t "${title_scratchpad}" &
fi

if $show; then
    WINID=`xdotool search --sync --name "^${title_scratchpad}$" 2>/dev/null`

    i3-msg "[title=\"^${title_scratchpad}$\"] move absolute position center" >/dev/null 2>/dev/null
    i3-msg "[title=\"^${title_scratchpad}$\"] scratchpad show" >/dev/null 2>/dev/null
    
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
[ $? -eq 0 ] && i3-msg "[title=\"^${title_scratchpad}$\"] scratchpad show" >/dev/null 2>/dev/null
