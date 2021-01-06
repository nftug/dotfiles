#!/bin/bash

##
# This script wait for events from `watch` and
# update the text by printing a new line.
##

current() {
    gdbus call --session --dest org.fcitx.Fcitx \
    --object-path /inputmethod \
    --method org.fcitx.Fcitx.InputMethod.GetCurrentIM |
    grep -Po "'([^']++)'" | sed -Ee "s/'([^']++)'/\\1/g"
}

imlist() {
    value="'([^']++)'"
    pattern="${value}, ${value}, ${value}"
    gdbus call --session --dest org.fcitx.Fcitx \
	  --object-path /inputmethod \
	  --method org.freedesktop.DBus.Properties.Get org.fcitx.Fcitx.InputMethod IMList |
	grep -Po "\($pattern, true\)" |
	sed -Ee "s/\($pattern.+\)/\\1,\\2,\\3/g"
}

# Strip `Keyboard - ` part from IM name then print
print_pretty_name() {
    imlist | sed -Ee 's/^Keyboard - //g' | grep "$(current)" | cut -d',' -f1
}

print_status_icon() {
    local im_current
    im_current=$(print_pretty_name)

    if [[ $im_current = "Mozc" ]]; then
    	#echo "%{F#81A1C1}%{T4}  %{T-}あ%{F-}"
	#echo "%{F#81A1C1} あ%{F-}"
	echo "%{F#4db6ac} あ%{F-}"
    else
    	#echo "%{T4}  %{T-}En"
	echo " En"
    fi
}

react() {
    # Without this, Polybar will display empty
    # string until you switch input method.

    #print_pretty_name
    print_status_icon

    # Track input method changes. Each new line read is an event fired from IM switch
    while true
    do
	read -r unused
	print_status_icon
    done 
}

watch() {
    gdbus monitor --session --dest org.fcitx.Fcitx | grep --line-buffered / | react
}

toggle() {
    state=`fcitx-remote`
    if [[ $state -gt 1 ]]; then
	fcitx-remote -c
    else
	fcitx-remote -o
    fi
}

case $1 in
    watch)
	watch
	;;
    toggle)
	toggle
	;;
esac

