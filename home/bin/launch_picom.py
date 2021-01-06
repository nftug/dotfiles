#!/usr/bin/env python
# -*- coding: utf-8 -*-

# Picomの起動ラッパー。
# Polybarの設定ファイルからbarの高さを取得し、picomのshadow-exclude-regの設定に加える。
# (Polybarにウィンドウの影が被らないようにする)

import configparser
import os
import subprocess
import errno
from mymodules.myprocess import MyProcess

conf_parser = configparser.ConfigParser()
conf_path = os.path.expanduser('~/.config/polybar/config')
sec_title = 'bar/main-' + os.uname()[1]

if os.path.exists(conf_path):
    with open(conf_path, encoding='utf-8') as file:
        conf_parser.read_file(file)
        read_default = conf_parser[sec_title]
        height = int(read_default.get('height'))
        border = int(read_default.get('border-size'))
        bar_height = height + border * 2

    MyProcess('picom', exact=True).kill(wait=True)

    subprocess.run(
        ['picom', '--experimental-backends', '-b',
         '--shadow-exclude-reg', 'x' + str(bar_height) + '+0+0'])

else:
    raise FileNotFoundError(errno.ENOENT, os.strerror(errno.ENOENT), conf_path)
