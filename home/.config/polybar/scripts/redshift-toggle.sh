#!/bin/sh

case $1 in
    toggle )
	pgrep ^redshift$ > /dev/null
	if [ $? -eq 0 ]; then
	    pkill redshift
	else
	    redshift
	fi
	;;
    label )
	pgrep ^redshift$ > /dev/null
	if [ $? -eq 0 ]; then
	    printf 'on'
	else
	    printf 'off'
	fi
	;;
esac
