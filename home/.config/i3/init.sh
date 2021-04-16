#!/bin/bash

xdg_autostart() {
    local config=$HOME/.config
    shopt -s nullglob
    if [[ -d "$config/autostart" ]]; then
        local i
        for i in $config/autostart/*.desktop; do
            grep -q -E "^Hidden=true" "$i" && continue
            if grep -q -E "^OnlyShowIn=" "$i"; then
                # need to test twice, as lack of the line entirely means we still run it
                grep -E "^OnlyShowIn=" "$i" | grep -q 'I3;' || continue
            fi
            grep -E "^NotShowIn=" "$i" | grep -q 'I3;' && continue

            local trycmd=$(grep -E "^TryExec=" "$i" | cut -d'=' -f2)
            if [[ -n "$trycmd" ]]; then
                which "$trycmd" >/dev/null 2>&1 || continue
            fi

            local cmd=$(grep -E "^Exec=" "$i" | cut -d'=' -f2)
            if [[ -n "$cmd" ]]; then
                $cmd &
            fi
        done
    fi
}

if [[ $DISPLAY != ":0" ]]; then
    xrdb ~/.vnc/Xresources 
    fcitx-autostart &
    nitrogen --restore &
    clipit &
    
else
    # [ -f /etc/xprofile ] && source /etc/xprofile
    # [ -f ~/.xprofile ] && source ~/.xprofile

    #eval $(/usr/bin/gnome-keyring-daemon --start --components=pkcs11,secrets,ssh)
    #export SSH_AUTH_SOCK

    ~/bin/ecl.sh -nc &

    fcitx-autostart &
    nitrogen --restore &
    clipit &
    update-checker 6h &
    # pamac-tray &
    /usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1 &

    (sleep 20; ~/.dotfiles/dotfiles.sh sync) &
    blueman-applet &
    
    if [[ -n `ip link show | grep wlp[0-9]s` ]]; then
	nm-applet &
	light-locker --no-lock-on-lid &	
    fi

    xdg_autostart &

fi
