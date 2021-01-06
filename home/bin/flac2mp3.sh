#!/bin/bash

if [[ -d $1 ]]; then
    OUTD="$1"
else
    OUTD="${HOME}/MP3_Music"
fi

find . -name "*.flac" -print0 | while IFS= read -r -d $'' a; do
  # give output correct extension
    OUTF="${a[@]/%flac/mp3}"
    TMPF="${a[@]/%flac/wav}"
    FILN="$(basename "${a}" .flac)"
    DIRN="$(dirname "${a}")"

    if [ -e "${DIRN}/cover.png" ]; then
	img="png"
    elif [ -e "${DIRN}/cover.jpg" ]; then
	img="jpg"
    fi
    
    echo $FILN
  # get the tags
  ARTIST=$(metaflac "$a" --show-tag=ARTIST | sed s/.*=//g)
  TITLE=$(metaflac "$a" --show-tag=TITLE | sed s/.*=//g)
  ALBUM=$(metaflac "$a" --show-tag=ALBUM | sed s/.*=//g)
  GENRE=$(metaflac "$a" --show-tag=GENRE | sed s/.*=//g)
  TRACKNUMBER=$(metaflac "$a" --show-tag=TRACKNUMBER | sed s/.*=//g)
  DATE=$(metaflac "$a" --show-tag=DATE | sed s/.*=//g)
  DISCNUMBER=$(metaflac "$a" --show-tag=DISCNUMBER | sed s/.*=//g)

  echo "Encoding ${ARTIST} - ${TITLE} (from ${ALBUM})..."
  
  OUTDIR="${OUTD}/${ARTIST}/${ALBUM}"
  OUTF_BASE="$(basename "${OUTF}")"
  
  if [ -e "${OUTDIR}/${OUTF_BASE}" ]; then
      echo "File Exists!"
  else
      # setting coverart (flac)
      metaflac --export-picture-to="${DIRN}/" "${a}" 2>/dev/null
      [ $? -ne 0 ] && metaflac --import-picture-from="${DIRN}/cover.$img" "${a}"
      
      # stream flac into the lame encoder
      flac -d "$a" -o "$TMPF"
      lame -q 0 --preset insane --highpass -1 --lowpass -1 -m s \
			     --add-id3v2 --pad-id3v2 --ignore-tag-errors \
			     --ta "$ARTIST" --tv TPE2="$ARTIST" --tt "$TITLE" --tl "$ALBUM" --tg "${GENRE:-12}" \
			     --tn "${TRACKNUMBER:-0}" --ty "$DATE" "$TMPF" "$OUTF"

      if [ -n "$DISCNUMBER" ]; then
	   eyeD3 -Q -d $DISCNUMBER "${OUTF}" > /dev/null
      fi
      
      # setting coverart (mp3)
      eyeD3 -Q --add-image="${DIRN}/cover.$img:FRONT_COVER" "${OUTF}" > /dev/null
      if [[ -z $(eyeD3 --no-color "${OUTF}"|grep "genre:") ]]; then
	  GENRE=$(metaflac "${a}" --show-tag=GENRE | sed s/.*=//g)
	  eyeD3 --non-std-genres -Q -G "${GENRE}" "${OUTF}" &>/dev/null 
      fi
      
      mkdir -p "${OUTDIR}"
      mv "${OUTF}" "${OUTDIR}"

      rm "$TMPF"
      
      [ ! -e "${OUTDIR}/cover.$img" ] && cp "${DIRN}/cover.$img" "${OUTDIR}"
  fi

  
done
