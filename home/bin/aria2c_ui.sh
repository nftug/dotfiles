#!/bin/bash

if [ ! -n "$1" ]; then
    echo "URLが指定されていません" >&2
    exit 1
fi

if ! type aria2c >/dev/null 2>&1; then
    echo "aria2がインストールされていません" >&2
    exit 1
fi

cd $HOME/Downloads

EXIT=/tmp/$(date +%s | sha256sum | base64 | head -c 8)
URL=$1

BASENAME="$(basename $URL)"
OUT="$(yad --file --save --width=800 --height=700 \
	   --title='ダウンロードの名前を選択' --filename="$PWD/$BASENAME" \
	   --confirm-overwrite='ファイルが既に存在します。上書きしますか？')"
DIRNAME="$(dirname "$OUT")"
[ ! -e "$DIRNAME" ] || [ -z "$OUT" ] && exit 1

OUTBASENAME="$(basename "$OUT")"
cd "$DIRNAME"

echo "[Debug] Dirname: $DIRNAME" >&2
echo "[Debug] Out: $OUT" >&2
echo "[Debug] Outbasename: $OUTBASENAME" >&2

a2cargs="-j 8 -s 8 -x 8 -k 5M --enable-color=false --summary-interval=1 --download-result=hide --allow-overwrite=true"

#echo $a2cargs >&2
#exit 1

( (
    aria2c $a2cargs --dir="$DIRNAME" --out="$OUTBASENAME" "$URL"
)& echo $! ) \
	| ( read PIPED_PID; while read -r line || [[ -n "$line" ]]; do
				line=$(echo "$line" | grep -i '^\[.*\]$'|sed 's/#//'|cut -d ' ' -f 2-|sed 's/\]$//')
				if [[ -n "$line" ]]; then
					percent=$(echo $line | sed 's/.*(\([0-9]\+\?\)%).*/\1/')
					# [[ $percent = 100 ]] && percent=99
					printf "%i\n" "$percent"
					echo "#$line"|sed 's/\[\(.*\?\)\]/\1/'
				fi
			done | yad --progress --auto-close \
						--title="aria2c" \
						--image=browser-download --borders=10 \
						--text="ダウンロード中: $OUTBASENAME" --button=gtk-cancel:1 \
						--width=500 --height=80 \
				|| ( echo "rm" > $EXIT; kill -0 $PIPED_PID && kill $PIPED_PID ) )

if [ -f $EXIT ]; then
    rm -f $EXIT
	#rm $(find $TMPDIR -type f -name $URL'.*' | grep part) &>/dev/null
    yad --image=gtk-dialog-question --ontop --borders=10 \
	--width=400 --height=120 \
	--text="ダウンロードをキャンセルしました。キャッシュファイルを削除しますか？" --title="aria2c" \
	--button=gtk-no:1 --button=gtk-yes:0
    
	if [ $? -eq 0 ]; then
		rm "${OUT%.torrent}"*
		echo "[Debug] Delete: ${OUT%.torrent}"* >&2
		if [ -e "${OUT}" ]; then
		    rm "${OUT}"
		    echo "[Debug] Delete: ${OUT}" >&2
		fi
	fi
	exit 1
else
    notify-send -i browser-download "$OUTBASENAME" "ダウンロードが完了しました"
    xdg-open "$DIRNAME"
fi
