#!/bin/bash

alpha="FF"
bg="263238"
fg="b9c3c7"
ac="4db6ac"
alertfg="ff5252"

#alpha="9F"
#bg="282A33"
#fg="f5f6f7"
#ac="9dccff"

menu_options=(
    -modi              'combi,drun,window,system:~/bin/rofi_sysmenu.sh'
    -show              'combi'
    -combi-modi        'window,drun,system'
    -sidebar-mode
    -window-format     '{c:15}{t}'
    -columns           '1'
    -padding           '45'
)

options=(
    -show-icons
    -font              'Sans 18.5'

    -width             '65'
    -padding           '30'
    -lines             '8'
    -columns           '1'
    -line-margin    '5'
    -line-padding   '5'
    -color-enabled     'true'
    -color-window      "argb:${alpha}${bg},argb:00${bg},argb:${alpha}${bg}"
    -color-normal      "argb:00${bg},#${fg},argb:00${bg},argb:${alpha}${ac},#EDFAFF"
    -color-active      "argb:00${bg},#${fg},argb:00${bg},argb:${alpha}${ac},#EDFAFF"
    -color-urgent      "argb:00${bg},#${alertfg},argb:00${bg},argb:${alpha}${ac},#${alertfg}"

    -separator-style   'none'
    
    -hide-scrollbar
    
    # argb:00 Keybindings
    -kb-cancel         'Escape,Control+g,Control+bracketleft,Control+c'
    -kb-mode-next      'Shift+Right,Control+Tab,Control+i'
    -kb-secondary-paste  'Ctrl+y'
    -kb-page-prev      'Alt+v'
    -kb-page-next      'Ctrl+v'

)

#if [ -p /dev/stdin ]; then
#    cat - | rofi "$@" "${options[@]}"

if [[ -z "$@" ]]; then
    rofi "${menu_options[@]}" "${options[@]}"
else
    rofi "$@" "${options[@]}" 
fi
