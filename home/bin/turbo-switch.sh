#!/bin/sh

# sudoersに /usr/bin/tlp /usr/bin/tlp-stat をNOPASSWDで追加しておくこと。

TLP=/usr/bin/tlp

case $LANG in
    ja_JP.* )
	TITLE='ターボブーストが${stat}です'
	LIST_STAT=('無効' '有効')
	MSG='現在の最大周波数: ${speed}'
	TITLE_ERR='ターボブーストの切替に失敗'
	ERR_404='${TLP}が見つかりません'
	;;
    * )
	TITLE='Turbo Boost ${stat}'
	LIST_STAT=('Disabled' 'Enabled')
	MSG='Current max frequency: ${speed}'
	TITLE_ERR='Switching Turbo Boost Failed'
	ERR_404='Not found ${TLP}.'
	;;
esac

function error() {
    notify-send -i dialog-error \
		"${TITLE_ERR}" \
		"$1"
    exit 1
}

if [ -x ${TLP} ]; then
    # no_turboは「ターボブーストが "無効" か」を示している
    # →次に切り替える "有効" 状態の値にそのまま使える
    stat_next=`cat /sys/devices/system/cpu/intel_pstate/no_turbo`
    
    cmd='sudo -n ${TLP} start -- CPU_BOOST_ON_BAT=${stat_next} CPU_BOOST_ON_AC=${stat_next}'
    stat=${LIST_STAT[$stat_next]}

    err=$(eval ${cmd} 2>&1 >/dev/null)
    
    if [ $? -eq 0 ]; then
	# from the source of neofetch
	speed="$(< "/sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq")"
	speed="$(echo ${speed} | awk '{ OFMT="%.2fGhz"; print $1 / 1000000 }')"
	
	notify-send -i device_cpu -t 5000 \
		    "$(eval echo ${TITLE})" \
		    "$(eval echo ${MSG})"
    else
	err=`echo "${err}" | head -1`
	error "${err}"
    fi
else
    error "$(eval echo ${ERR_404})"
fi
