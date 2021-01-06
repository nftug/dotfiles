#!/bin/bash

LANG=C

base_ex=$(pactree -a -d 1 base | sed '1d' | sed 's/^.-//g')

if [[ $1 = "-a" ]]; then
    pkglist=`pacman -Qqem`
    excluded=`echo 'my-*'`
else
    pkglist=`pacman -Qqen`
    excluded=`pacman -Sgq base-devel`
    excluded=$(echo -e "$excluded\n$base_ex")
    excluded=`echo $excluded|sed 's/ / -e /g'`
fi

echo "$pkglist" | while read line; do
    if [ ! -n "$(echo $line | grep -x -e $excluded)" ]; then
	echo $line
    fi
done
