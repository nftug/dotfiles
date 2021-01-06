#!/bin/bash

TMPDIR=$HOME/.cache/ytmpv
VIDEODIR=$HOME/Videos/YouTube

[ ! -d "$TMPDIR" ] && mkdir -p "$TMPDIR"
[ ! -d "$VIDEODIR" ] && mkdir -p "$VIDEODIR"

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

__yad_center() {
    local d_w d_h d_x d_y stdout ret
    
    __get_resolution
    d_w=$1; d_h=$2
    d_x=$(( ( $w - $d_w ) / 2 ))
    d_y=$(( ( $h - $d_h ) / 2 ))

    shift 2
    arrcmd=(yad --geometry=${d_w}x${d_h}+${d_x}+${d_y} "$@")

    if [ -p /dev/stdin ]; then
	stdout=`cat - | "${arrcmd[@]}"`
	ret=$?
    else
	stdout=`"${arrcmd[@]}"`
	ret=$?
    fi
    
    echo "$stdout"
    return $ret
}

__download_video() {
    # Ref: https://forums.bunsenlabs.org/viewtopic.php?pid=28128#p28128
    local EXIT PIPED_PID URL SAVEDIR DATA VTMP a2carg TAMP
    
    EXIT=/tmp/$(date +%s | sha256sum | base64 | head -c 8)
    URL=$2
    URL=${URL##*'='}
    a2cargs="-j 8 -s 8 -x 8 -k 5M --dir=$TMPDIR --enable-color=false --summary-interval=1 --download-result=hide --allow-overwrite=true"
    
    DATA=$(youtube-dl -f "'$1'" \
		      --write-auto-sub --all-subs \
	              --external-downloader aria2c \
		      --external-downloader-args "--dry-run $a2cargs" $URL 2>/dev/null)
    #echo "$DATA" >&2
    if [ -n "`echo "$DATA"|grep -i '^\[download\] .* downloaded$'`" ]; then
	VTMP=$(echo "$DATA"| grep -i '^\[download\] .* downloaded$' \
		   | sed 's/^\[download\] \(.*\?\) has already been downloaded$/\1/')
    else
	VTMP=$(echo "$DATA"| grep -i "^\[download\] Destination:" \
		   | awk '{print substr($0,index($0,":")+2)}')
    fi

    if [ ! -n "$VTMP" ]; then
	echo "ビデオ用ファイル名を取得できません！" >&2
	exit 1
    fi
    
    find $TMPDIR -type f -name 'tmp_'$URL'.*' -print0 | xargs --no-run-if-empty -0 rm
    find $TMPDIR -type f -name "*$VTMP*" -print0 | xargs --no-run-if-empty -0 rm

    cd $TMPDIR
    
    ( (
	youtube-dl -f "'$1'" --add-metadata --external-downloader aria2c \
		   --external-downloader-args "$a2cargs" $URL
	while [ ! -f  "$VTMP" ]; do
	    sleep 0.5
	done
	mv "$VTMP" tmp_$URL.mkv
	youtube-dl -f 'bestaudio' -o tmp_$URL.snd $URL 
	ffmpeg -loglevel error -i tmp_$URL.mkv -f ffmetadata tmp_$URL.ini >/dev/null
	ffmpeg -loglevel error -i tmp_$URL.mkv -i tmp_$URL.snd -acodec copy -vcodec copy $URL.mkv >/dev/null
	ffmpeg -loglevel error -i $URL.mkv -i tmp_$URL.ini -map_metadata 1 -codec copy $URL.mkv > /dev/null
    )& echo $! ) \
	| ( read PIPED_PID; while read -r line || [[ -n "$line" ]]; do
				if [ ! -f tmp_$URL.snd ] && [ ! -f tmp_$URL.mkv ]; then
				    # echo $line >> log.txt
				    line=$(echo "$line" | grep -i '^\[#.*CN:[0-9]\+.*\]$'|sed 's/#//'|cut -d ' ' -f 2-|sed 's/\]$//')
				    
				    if [[ -n "$line" ]]; then
					percent=$(echo $line | sed 's/.*(\([0-9]\+\?\)%).*/\1/')
					[[ $percent = 100 ]] && percent=99
					printf "%i\n" "$percent"
					echo "#$line"|sed 's/^\[\(.*\?\)\]$/\1/'
				    fi
				else				   
				    #if [[ "$(echo "$line" | grep '[0-9]*%')" ]]; then
				    #	percent=$(echo $line | sed 's/.* \([0-9]\+\.\?[0-9]\?\)% .*/\1/')
				    #	[ $percent = 100.0 ] && percent=99
				    #	printf "%.f\n" "$percent"
				    #   fi
				    echo "99%"
				    echo "#まもなく完了します..."
				fi
			    done | yad --geometry=500x80 --progress --auto-close \
				       --title="ytmpv - 動画のダウンロード" \
				       --image=browser-download --borders=10 \
				       --text="ダウンロード中: ${TITLE//&/&amp;}" --button='キャンセル(C)':1 \
				|| ( echo "rm" > $EXIT; kill -0 $PIPED_PID && kill $PIPED_PID ) )    
    if [ -f $EXIT ]; then
	rm -f $EXIT
	#rm $(find $TMPDIR -type f -name $URL'.*' | grep part) &>/dev/null
	find $TMPDIR -type f -name 'tmp_'$URL'.*' -print0 | xargs --no-run-if-empty -0 rm
	find $TMPDIR -type f -name "*$VTMP*" -print0 | xargs --no-run-if-empty -0 rm
	exit 1
    else
	rm $TMPDIR/tmp_*
	echo "$TMPDIR/$URL.mkv"
    fi
}   

#
# ここから
#

if [ ! -n "$1" ]; then
    yad --geometry=300x80 --image=gtk-dialog-error --ontop --borders=10 \
	--text="URLが指定されていません" --title="ytmpv" \
	--button="OK":0
    exit 1
fi

if ! type aria2c >/dev/null 2>&1; then
    yad --geometry=300x80 --image=gtk-dialog-error --ontop --borders=10 \
	--text="aria2cがインストールされていません" --title="ytmpv" \
	--button="OK":0
    exit 1
fi

playerctl -p chromium pause

#browser_window_id=$(xdotool search --name --onlyvisible "Chromium")
#xdotool windowactivate $browser_window_id
#sleep 0.5s
#xdotool key space


URL="$1"
VIDEO_ID=`echo -n $URL | sed 's/.*v=\([^\&]*\).*/\1/'`
URL_PURE="https://www.youtube.com/watch?v=$VIDEO_ID"
TITLE=`youtube-dl --get-filename $URL_PURE`
TITLE="${TITLE%.*}"

if [ ! -n "$TITLE" ]; then
    notify-send "タイトルが取得できません"
    exit 1
fi


d_reslist="デフォルト (フルHD画質 [1080p]),4K画質 [2160p],2K画質 [1440p],フルHD画質 [1080p],HD画質 [720p],SD画質 [480p]"
d_cmdlist="ストリーミングで再生 (1080p以下のみ),ダウンロード完了後に再生,ファイルにダウンロードする"

d_data=`yad --geometry=400x225 --borders=16 --form \
	      --image=mpv --image-on-top --ontop --item-separator=',' \
	      --text='動画の再生オプションを指定してください\n(画質は最良値を指定)' --title='ytmpv' \
	      --field='タイトル' --field='解像度':CB --field='操作':CB \
	      --field='60fps動画を指定する':CHK \
	      --field='H.264コーデックを指定する':CHK \
	      --button="キャンセル":1 --button="OK":0 \
	      "$TITLE" "$d_reslist" "$d_cmdlist" FALSE`

[ $? -ne 0 ] && exit 1

TITLE="$(echo "$d_data"|cut -d '|' -f 1)"
res=$(echo "$d_data" | cut -d '|' -f 2 | sed 's/.*\[\(.*\)p\].*/\1/')

#res=$(echo $t_res|sed -e 's/.*\[\([0-9]\+\)p\].*/\1/')
# case "$(echo "$d_data"|cut -d '|' -f 2)" in
    # "$(echo "$d_reslist"|gawk -F, '{print $1}')" ) res=1080 ;;
    # "$(echo "$d_reslist"|gawk -F, '{print $2}')" ) res=2160 ;;
    # "$(echo "$d_reslist"|gawk -F, '{print $3}')" ) res=1440 ;;
    # "$(echo "$d_reslist"|gawk -F, '{print $4}')" ) res=1080 ;;
    # "$(echo "$d_reslist"|gawk -F, '{print $5}')" ) res=720 ;;
    # "$(echo "$d_reslist"|gawk -F, '{print $6}')" ) res=480 ;;
# esac



case "$(echo "$d_data"|cut -d '|' -f 3)" in
    "$(echo "$d_cmdlist"|gawk -F, '{print $1}')" ) cmd=1 ;;
    "$(echo "$d_cmdlist"|gawk -F, '{print $2}')" ) cmd=2 ;;
    "$(echo "$d_cmdlist"|gawk -F, '{print $3}')" ) cmd=3 ;;
esac

# 4k以上の場合、ストリーミングではなくダウンロードしてから再生
[ $res -gt 2160 -a $cmd -eq 1 ] && cmd=2

case "$(echo "$d_data"|cut -d '|' -f 4)" in
    "TRUE" ) highfps=true ;;
    "FALSE" ) highfps=false ;;
esac

# 処理開始
if $highfps; then
    var_format="bestvideo[height<=?${res}][fps>=?50]"
else
    var_format="bestvideo[height<=?${res}][fps<?50]"
fi

[[ $(echo "$d_data"|cut -d '|' -f 5) = "TRUE" ]] && var_format+='[vcodec*=avc1]'
    
case $cmd in
    1 )
    # celluloid --mpv-options="--ytdl-format=${var_format}+bestaudio/best" $URL_PURE
    mpv --ytdl-format=${var_format}+bestaudio/best $URL_PURE
    ;;
    2 )
	videofile=`__download_video "'$var_format'" "$URL_PURE"`
	videofile=`echo ${videofile} | sed -e "s/[\r\n]\+//g"`
	if [ $? -eq 0 -a -f $videofile ]; then
	    # celluloid $videofile
	    mpv $videofile
	    
	    zenity --icon-name=dialog-question --question --no-wrap --text "視聴後のビデオを動画フォルダに保存しますか？" --title "ytmpv - $TITLE"
	    
	    if [ $? -eq 0 ]; then
		mv $videofile $VIDEODIR/"$TITLE".mkv
	    else
		rm $videofile
	    fi
	else
	    notify-send -a "ytmpv" --icon "dialog-error" "ダウンロードの中断" "動画のダウンロードがキャンセルされました:\n $TITLE"
	fi
	;;
    3 )
	time videofile=`__download_video "'$var_format'" "$URL_PURE"`
        videofile=`echo ${videofile} | sed -e "s/[\r\n]\+//g"`
	if [ $? -eq 0 -a -f $videofile ]; then
	    mv $videofile $VIDEODIR/"$TITLE".mkv
	    notify-send -a "ytmpv" --icon "dialog-information" "ダウンロードの完了" "動画のダウンロードが完了しました:\n $TITLE"
	else
	    notify-send -a "ytmpv" --icon "dialog-error" "ダウンロードの中断" "動画のダウンロードがキャンセルされました:\n $TITLE"
	fi
	;;
esac






