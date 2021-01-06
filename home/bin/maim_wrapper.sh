#!/bin/bash

OUTDIR="$HOME/Pictures/Screenshot"
FILENAME="$(date '+%Y-%m-%d %H-%M-%S').png"
OUT="${OUTDIR}/${FILENAME}"
TMPOUT="/tmp/${FILENAME}"

ROFI="$HOME/bin/rofi_launch.sh"
VIEWER=/usr/bin/viewnior
ID_DUNST=876
PS_VIEWER=''

HIGHLIGHT='0,0.74,0.83,0.3'
# HIGHLIGHT='0.37,0.50,0.67,0.4'

function _clean
{
    kill $PS_VIEWER
    [ -f "${TMPOUT}" ] && rm "${TMPOUT}"
}

function _cancel
{
    local msg=$1
    
    dunstify -r $ID_DUNST -i dialog-error -t 5000 \
	      "スクリーンショットをキャンセルしました" "$msg"
    _clean
    exit 1
}

function _shot
{
    dunstify -C $ID_DUNST
    sleep 0.2
    
    [ -x /usr/bin/maim ] || _cancel "/usr/bin/maimがインストールされていません。"
    eval maim ${@:-} || _cancel "撮影がキャンセルされました。"
    $VIEWER "${TMPOUT}" & 
    PS_VIEWER=$!
    
    local winid=`xdotool search --sync --name "^$FILENAME.*"`
    xdotool windowactivate $winid

    # 保存メニュー
    local items=(
	'ファイル\0icon\x1fdocument-save\x1fmeta\x1fsave'
	'クリップボード\0icon\x1fedit-copy\x1fmeta\x1fcopy'
	'キャンセル\0icon\x1fgtk-cancel\x1fmeta\x1fcancel'
    )

    killall -q rofi
    while pgrep -u $UID -x rofi >/dev/null; do sleep 1; done
    
    num=$( (for item in "${items[@]}"; do echo -e ${item}; done) | \
	      $ROFI -dmenu -format i -p '保存先' -lines 1   \
		    -width -70 -location 6 -monitor -2 \
		    -yoffset -10 -columns ${#items[@]} -padding 25 )
    ret=$?

    
    [ ! $ret -eq 0 ] || [ $num -eq 2 ] && _cancel "保存がキャンセルされました"
    
    case $num in
	0)
	    cp "$TMPOUT" "$OUT"
	    _clean
	    action=$(dunstify -r $ID_DUNST -i accessories-screenshot -t 5000 \
			      "スクリーンショットを保存しました" "$OUT" \
			      --action="open_dir,保存先を開く" \
			      --action="open_file,ファイルを開く")
	    case "$action" in
		"open_dir" )
		    xdg-open "$OUTDIR" ;;
		"open_file" )
		    xdg-open "$OUT" ;;
	    esac
	    ;;
	1)
	    cat "$TMPOUT" | xclip -selection clipboard -t image/png
	    _clean
	    dunstify -r $ID_DUNST -i accessories-screenshot -t 5000 \
		     "スクリーンショットをコピーしました" \
		     "クリップボードから画像を貼り付けできます。"
	    ;; 
    esac
}



function __main__
{

    [ ! -d "${OUTDIR}" ] && mkdir -p "${OUTDIR}"

    getopts si OPT
    case $OPT in
	s)
	    # 選択モード
	    _shot -sul -c "${HIGHLIGHT}" "\"${TMPOUT}\""
	    ;;
	i)
	    # TODO: インタラクティブモードを作る
	    echo "ここにインタラクティブモードの処理が入ります。"
	    exit
	    ;;
	h)
	    #TODO: ヘルプを作る
	    echo "ここにヘルプの説明書きが入ります。"
	    exit
	    ;;
	* )
	    # 通常モード (画面撮影)
	    _shot -u "\"${TMPOUT}\""
	    ;;
    esac		 
}

__main__ $@
