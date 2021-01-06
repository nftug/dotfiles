#!/bin/bash

bat_dir="/sys/class/power_supply/max170xx_battery"
chg_dir="/sys/class/power_supply/bq24190-charger"
typec_dir="/sys/class/power_supply/tcpm-source-psy-i2c-fusb302"

toint() {
  printf "%.0f" "$1"
}

tomicro() {
  printf "%.0f" "$(bc <<<"${1}*1000000")"
}

frommicro() {
  if [ $# -ge 2 ]; then
    _digits="$2"
  else
    _digits='2'
  fi
  bc <<<"scale=${_digits}; ${1}/1000000"
}

msg() {
  printf '%s\n' "$@"
}

errmsg() {
  msg "$@" > /dev/stderr
}

msg_format_data() {
  printf '%-21s %-19s  %s\n' "$@"
}


printusage() {
  msg "Usage:"
  msg "  To print all information, invoke without arguments:"
  msg "    $0"
  msg ""
  msg "  To get or set a single properties:"
  msg "    $0 <property> [<value>]"
  msg ""
  msg "  (invokation without '<value>' prints the current setting)"
  msg "  where '<property>' is one of:"
  msg "  * input_cur -- sets the charger's input current limit in A"
  msg "  * chg_cur   -- sets the charge current limit in A"
  msg "  * chg_v     -- sets the charge voltage limit in V"
  msg "  * chg_type  -- Set charge type. Supported: 'Trickle', 'Fast'."
  msg ""
  msg "  To get this help text:"
  msg "    $0 -h|-help|--help"
}


# If arguments are supplied, modify settings and exit. Otherwise go through and print the information.
if [ $# -eq 1 ] || [ $# -eq 2 ]; then
  property="$1"
  if [ $# -eq 2 ]; then
    value="$2"
  fi
  case "${property}" in
    input_cur)
      if [ $# -eq 2 ]; then
        printf '%s' "$(tomicro "${value}")" > "${chg_dir}/input_current_limit"
      else
        msg "$(frommicro "$(<"${chg_dir}/input_current_limit")")"
      fi
      _exitcode=$?
    ;;
    chg_cur)
      if [ $# -eq 2 ]; then
        printf '%s' "$(tomicro "${value}")" > "${chg_dir}/constant_charge_current"
      else
        msg "$(frommicro "$(<"${chg_dir}/constant_charge_current")")"
      fi
      _exitcode=$?
    ;;
    chg_v)
      if [ $# -eq 2 ]; then
        printf '%s' "$(tomicro "${value}")" > "${chg_dir}/constant_charge_voltage"
      else
        msg "$(frommicro "$(<"${chg_dir}/constant_charge_voltage")")"
      fi
      _exitcode=$?
    ;;
    chg_type)
      if [ $# -eq 2 ]; then
        printf '%s' "${value}" > "${chg_dir}/charge_type"
      else
        msg "$(<"${chg_dir}/charge_type")"
      fi
      _exitcode=$?
    ;;
    '-h'|'--help'|'-help')
      printusage
    ;;
    *)
      errmsg "$0: Error: Argument '${property}' not supported."
      errmsg "Invoke with '-h' to get help."
      _exitcode=2
    ;;
  esac
  exit ${_exitcode}
elif [ $# -eq 0 ]; then
  true
else
  errmsg "$0: Error: Wrong amount of arguments ($#) specified."
  errmsg ""
  errmsg "$(printusage)"
  exit 1
fi



bat_u_now="$(frommicro "$(<"${bat_dir}/voltage_now")")"
bat_u_avg="$(frommicro "$(<"${bat_dir}/voltage_avg")")"
bat_u_min="$(frommicro "$(<"${bat_dir}/voltage_min")")"
bat_u_min_design="$(frommicro "$(<"${bat_dir}/voltage_min_design")")"
bat_u_max="$(frommicro "$(<"${bat_dir}/voltage_max")")"
bat_u_opencircuit="$(frommicro "$(<"${bat_dir}/voltage_ocv")")"
bat_i_now="$(frommicro "$(<"${bat_dir}/current_now")")"
bat_i_avg="$(frommicro "$(<"${bat_dir}/current_avg")")"
bat_percentage="$(<"${bat_dir}/capacity")"
bat_charge="$(frommicro "$(<"${bat_dir}/charge_now")")"
bat_charge_counter="$(frommicro "$(<"${bat_dir}/charge_counter")")"
bat_charge_full="$(frommicro "$(<"${bat_dir}/charge_full")")"
bat_charge_full_design="$(frommicro "$(<"${bat_dir}/charge_full_design")")"
bat_cycle_count="$(<"${bat_dir}/cycle_count")"
bat_health="$(<"${bat_dir}/health")"
bat_p_now="$(bc <<<"${bat_u_now}*${bat_i_now}")"
bat_p_avg="$(bc <<<"${bat_u_avg}*${bat_i_avg}")"

chg_status="$(<"${chg_dir}/status")"
chg_online="$(<"${chg_dir}/online")"
chg_health="$(<"${chg_dir}/health")"
chg_terminiation_current="$(frommicro "$(<"${chg_dir}/charge_term_current")" 3)"
chg_type="$(<"${chg_dir}/charge_type")"
chg_i_limit="$(frommicro "$(<"${chg_dir}/constant_charge_current")" 3)"
chg_i_limit_max="$(frommicro "$(<"${chg_dir}/constant_charge_current_max")" 3)"
chg_u_limit="$(frommicro "$(<"${chg_dir}/constant_charge_voltage")" 3)"
chg_u_limit_max="$(frommicro "$(<"${chg_dir}/constant_charge_voltage_max")" 3)"
chg_input_i_limit="$(frommicro "$(<"${chg_dir}/input_current_limit")" 2)"
chg_precharge_i="$(frommicro "$(<"${chg_dir}/precharge_current")" 3)"

typec_i_max="$(frommicro "$(<"${typec_dir}/current_max")" 1)"
typec_i_now="$(frommicro "$(<"${typec_dir}/current_now")" 1)"
typec_online="$(<"${typec_dir}/online")"
typec_usb_type="$(<"${typec_dir}/usb_type")"
typec_u_max="$(frommicro "$(<"${typec_dir}/voltage_max")" 0)"
typec_u_min="$(frommicro "$(<"${typec_dir}/voltage_min")" 0)"
typec_u_now="$(frommicro "$(<"${typec_dir}/voltage_now")" 0)"


msg '-- Battery: --'

msg_format_data 'Percentage:' "${bat_percentage}%"
msg_format_data 'Health:' "${bat_health}."
msg_format_data 'Cycles:' "${bat_cycle_count}"
msg_format_data 'Voltage:' "${bat_u_avg}/${bat_u_now}" 'Avg/Now (V)'
msg_format_data 'V. limits:' "${bat_u_max}/${bat_u_min} ${bat_u_opencircuit}/${bat_u_min_design}" 'Max/Min Open_Circuit/Min_Design (V)'
msg_format_data 'Current:' "${bat_i_avg}/${bat_i_now}" 'Avg/Now (A)'
msg_format_data 'Power:' "${bat_p_avg}/${bat_p_now}" 'Avg/Now (W)'
msg_format_data 'Charge:' "${bat_charge}/${bat_charge_counter}" 'Curr./Counter (Ah)'
msg_format_data 'Ch. limits:' "${bat_charge_full}/${bat_charge_full_design}" 'Full/Design (Ah)'
msg ''

msg "-- Charger (Values with '(*)' can be changed by user, see option '-h'): --"
case "${typec_online}" in
  "0")
    msg_format_data 'Status:' 'Not connected.'  
  ;;
  "1")
    msg_format_data 'Status:' 'Connected.'
  ;;
  *)
    msg_format_data 'Status:' "Other: ${typec_online}."
  ;;
esac
msg_format_data 'Action:' "${chg_status}."
msg_format_data 'Health:' "${chg_health}."
msg_format_data 'Charging type:' "${chg_type}." '(*)'
msg_format_data 'Chg. end det. I:' "${chg_terminiation_current} A"
msg_format_data 'Pre-/trickle chg. I:' "${chg_precharge_i} A"
msg_format_data 'Voltage limits:' "${chg_u_limit}/${chg_u_limit_max}" 'Curr.(*)/Max (V)'
msg_format_data 'Current limits:' "${chg_i_limit}/${chg_i_limit_max}" 'Curr.(*)/Max (A)'
msg_format_data 'Input current limit:' "${chg_input_i_limit} A" '(*)'
msg ''

msg '-- USB-C: --'
case "${typec_online}" in
  "0")
    msg_format_data 'Status:' 'Not connected.'  
  ;;
  "1")
    msg_format_data 'Status:' 'Connected.'
  ;;
  *)
    msg_format_data 'Status:' "Other: ${typec_online}."
  ;;
esac
msg_format_data 'Type:' "${typec_usb_type}"
msg_format_data 'Voltage:' "${typec_u_now} ${typec_u_max}/${typec_u_min}" 'Now Max/Min (V)'
msg_format_data 'Negotiated Current:' "${typec_i_now} ${typec_i_max}" 'Now Max (A)'
