#!/bin/bash

COVERDIR=/tmp/coverdir
COVER_TMP=${COVERDIR}/cover.tmp
BIN=${HOME}/bin

usage_exit() {
        echo "Usage: $0 [-d directory to output to] artist album" 1>&2
        exit 1
}

__cover_url() {
    # CLIENT_IDとCLIENT_SECRETはDropboxから読み込む
    source $HOME/Dropbox/.dotfiles/spotify_credentials.conf

    SPOTIFY_SEARCH_API="https://api.spotify.com/v1/search"
    SPOTIFY_TOKEN_URI="https://accounts.spotify.com/api/token"

    SHPOTIFY_CREDENTIALS=$(printf "${CLIENT_ID}:${CLIENT_SECRET}" | base64 | tr -d "\n")

    # GetAccessToken

    if [ $# -ne 2 ]; then
	echo "Args must be [ARTIST] [ALBUM]"
	exit 1
    fi


    SPOTIFY_TOKEN_RESPONSE_DATA=$( \
				   curl "${SPOTIFY_TOKEN_URI}" \
					--silent \
					-X "POST" \
					-H "Authorization: Basic ${SHPOTIFY_CREDENTIALS}" \
					-d "grant_type=client_credentials" \
			       )
    if ! [[ "${SPOTIFY_TOKEN_RESPONSE_DATA}" =~ "access_token" ]]; then
	echo "Autorization failed, please check ${USER_CONFG_FILE}" >&2
	echo "${SPOTIFY_TOKEN_RESPONSE_DATA}" >&2
	exit 1
    fi
    SPOTIFY_ACCESS_TOKEN=$( \
			    printf "${SPOTIFY_TOKEN_RESPONSE_DATA}" \
				| grep -E -o '"access_token":".*",' \
				| sed 's/"access_token"://g' \
				| sed 's/"//g' \
				| sed 's/,.*//g' \
			)

    artist=`echo $1 | sed -e 's/\\\\//' -e 's/\///' | nkf -WwMQ | tr = %`
    album=`echo $2 | sed -e 's/\\\\//' -e 's/\///' | nkf -WwMQ | tr = %`

    imgurl=$(curl -s -G $SPOTIFY_SEARCH_API \
     -H "Authorization: Bearer ${SPOTIFY_ACCESS_TOKEN}" \
     -H "Accept: application/json" \
     -d "q=artist:${artist}%20album:${album}" \
     -d "type=album&limit=5&offset=0" \
    | jq -rc '.albums .items[] | .images[] | select(.height >= 500) | .url')


     echo "$(curl -s -G $SPOTIFY_SEARCH_API \
     -H "Authorization: Bearer ${SPOTIFY_ACCESS_TOKEN}" \
     -H "Accept: application/json" \
     -d "q=artist:${artist}%20album:${album}" \
     -d "type=album&limit=5&offset=0" \
    | jq )" >&2
    
    if [ -n "$imgurl" ]; then
	echo "$imgurl"
	exit 0
    else
	echo "Not found cover image" >&2
	exit 1
    fi
}

while getopts d:h OPT
do
    case $OPT in
	d) OUTDIR=$OPTARG
	   ;;
	h) usage_exit
	   ;;
	\?) usage_exit
	    ;;
    esac
done
shift $((OPTIND - 1))

[ -z "$1" -o -z "$2" ] && usage_exit
[ -z "$OUTDIR" -o ! -d "$OUTDIR" ] && OUTDIR=${HOME}

mkdir -p ${COVERDIR}

i=1
md5=($(echo -n "$1#$2"|md5sum))

__cover_url "$1" "$2"|while read line
do
    curl ${line} -so ${COVER_TMP} >/dev/null 2>&1
    format=`identify -format '%m' ${COVER_TMP}`
    if [[ $format = "JPEG" ]]; then
	mv ${COVER_TMP} ${COVERDIR}/${md5}${i}.jpg
    elif [[ $format = "PNG" ]]; then
	mv ${COVER_TMP} ${COVERDIR}/${md5}${i}.png
    fi
    (( i++ ))
done

cd ${COVERDIR}
file="$(yad --file --file-filter="Coverart Files (*.jpg *.jpeg *.png)| *.jpg *.JPG *.jpeg *.JPEG *.png *.PNG" --add-preview)"

[[ -f "${file}" ]] && cp ${file} "${OUTDIR}/cover.${file##*.}"

rm "${COVERDIR}"/${md5}*

if [ -z "${file}" ]; then
    echo "Output file is empty" 1>&2
    exit 1
else
    echo "${OUTDIR}/cover.${file##*.}"
fi


