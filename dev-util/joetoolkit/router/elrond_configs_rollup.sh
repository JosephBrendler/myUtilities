#!/bin/bash

script_header_installed_dir="/usr/sbin"
#script_header_installed_dir=/home/joe/myUtilities/dev-util/script_header_joetoo
header="${script_header_installed_dir%/}/script_header_joetoo"
echo "header: $header"

# source script_header
# shellcheck source="/usr/sbin/script_header_joetoo"
if [ -f "$header" ]; then
  # source it if it isn't already sourced
  # (redundant since it should also make this same check at its top section)
  if [ "$JOETOO_ENVIRONMENT_ALREADY_SOURCED" ]; then
    source_finding="was already sourced"
  else
    . "$header"
 #   . "${header}_ssh"   # also source the ssh module
    source_finding="sourced"
  fi
else
  printf '%s' "failed to source header; cannot continue"
  exit 1
fi
# verify sourced script_header
printf '%s' "Checking for header commands to confirm sourcing"
if command -v toc >/dev/null 2>&1 && command -v run_sequence >/dev/null 2>&1 ; then
  printf '%s\n' " success; header ${source_finding}"
else
  printf '%s\n' " Failed; header not sourced; cannot continue"; exit 1
fi

# verify sourced script_header ssh key management module
#printf '%s' "Checking for ssh header commands to confirm sourcing"
#if command -v load_key >/dev/null 2>&1 && command -v run_sequence >/dev/null 2>&1 ; then
#  printf '%s\n' " success; ssh header ${source_finding}"
#else
#  printf '%s\n' " Failed; ssh header not sourced; cannot continue"; exit 1
#fi

# note: considered sourcing script_header_joetoo_ssh, but there is not benefit for this script
#   ssh agent will ask for password when script runs scp - (same experience if using
#   script_header_joetoo_ssh start -> load_key -> unload_key -> stop (but with more overhead)

user=joe
win_user=joebr
rollup_file="/home/${user}/script/elrond_configs_rollup"
target="${user}@gmki91:/home/${user}/"
#target="${win_user}@joelaptop:C:/Users/${win_user}/Desktop/"

#SSH_KEY="/home/${user}/.ssh/id_rsa"

#bremoji $wrench
#j_msg -${notice} -p "starting ssh agent ..."
#start_ssh_agent; handle_result $? "" "" -$notice || die "failed to start_ssh_agent"

configs=(
/etc/shorewall6/snat /etc/shorewall6/interfaces /etc/shorewall6/zones
/etc/shorewall6/rules /etc/shorewall6/policy
/etc/shorewall/snat /etc/shorewall/interfaces /etc/shorewall/zones
/etc/shorewall/rules /etc/shorewall/policy
/etc/conf.d/chronyd /etc/chrony.conf
/etc/dnsmasq.conf /etc/openvpn/server.conf /etc/hosts /etc/conf.d/net
/etc/radvd.conf /etc/dhcpcd.conf /etc/resolv.conf /etc/stubby/stubby.yml
/etc/ulogd.conf /etc/syslog.conf /etc/logrotate.conf
/etc/ssh/sshd_config /etc/ssh/sshd_config.d/01_joetoo_sshd_config.conf
/etc/ssh/sshd_config.d/9999999gentoo-pam.conf /etc/ssh/sshd_config.d/9999999gentoo-subsystem.conf
/etc/ssh/sshd_config.d/9999999gentoo.conf /etc/conf.d/net /etc/conf.d/apache2
/etc/conf.d/distccd /etc/conf.d/dnsmasq /etc/conf.d/shorewall /etc/conf.d/shorewall6
/etc/hostapd/hostapd.conf /etc/conf.d/hostapd
/etc/rsyncd.conf /etc/conf.d/rsyncd
/etc/openvpn/server.conf /etc/conf.d/openvpn
/etc/haveged.conf /etc/conf.d/haveged
/etc/samba/smb.conf /etc/conf.d/samba
/etc/conf.d/stubby /etc/conf.d/node_exporter /etc/conf.d/prometheus
/etc/prometheus/prometheus.yml /etc/sysconfig/node_exporter
/etc/sysstat /etc/sysstat.ioconf
)

echo "# elrond_configs_rollup as of $(timestamp)" > "${rollup_file}"

for x in "${configs[@]}" ; do
  j_msg -${notice} -mp "\n$x"
  j_msg -${notice} -mp -- $(repeat '-' ${#x});
  grep -Ev --color=auto "(^\s*$|^#)" 2>/dev/null $x;
done >> "${rollup_file}" || die "failed to roll up configs"

text2pdf "${rollup_file}"
cat "${rollup_file}"


#bremoji $wrench
#j_msg -${notice} -p "loading ssh key ..."
#load_key; handle_result $? "" "" -$notice || die "failed to load_key"

# source environment variables to guarantee persistence
#if [ -f "${AGENT_ENV_FILE}" ]; then
#  j_msg -${notice} -p -n "sourcing AGENT_ENV_FILE..."
#  source "${AGENT_ENV_FILE}"
#  right_status $? ${notice} || die "failed to source AGENT_ENV_FILE" 1
#else
#  j_msg -${err} "AGENT_ENV_FILE not found"
#  return 2
#fi

bremoji $hammer
j_msg -${notice} -p "now transferring ${rollup_file} to ${target} with scp ..."
#sudo -u ${user} scp "${rollup_file}"{,.pdf} "${target}"  || die "failed to scp rollup to ${target}"
sudo -u "${user}" rsync -av --exclude="*.sh" "${rollup_file}"* "${target}" || die "failed to rsync files"

#bremoji $wrench
#j_msg -${notice} -p "unloading ssh key ..."
#unload_key; handle_result $? "" "" -$notice || die "failed to unload_key"

#bremoji $wrench
#j_msg -${notice} -p "stopping ssh agent ..."
#stop_ssh_agent; handle_result $? "" "" -$notice || die "failed to stop_ssh_agent"

j_msg -${notice} -p -M $idx_face_beam "${BGon}Success${Boff}"
