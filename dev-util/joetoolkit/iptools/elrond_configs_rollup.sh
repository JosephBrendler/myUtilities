#!/bin/bash
source /usr/sbin/script_header_joetoo
source /usr/sbin/script_header_joetoo_unicode

user=joe
win_user=joebr
rollup_file="/home/${user}/script/elrond_configs_rollup"
#target="${user}@gmki91:/home/${user}/"
target="${win_user}@joelaptop:C:/Users/${win_user}/Desktop/"

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
/etc/conf.d/stubby /etc/conf.d/node_exporter /etc/conf.d/prometheus
/etc/prometheus/prometheus.yml /etc/sysconfig/node_exporter
/etc/sysstat /etc/sysstat.ioconf
)

timestamp() {
    echo "$(date '+%Y-%m-%d_%H:%M:%S')"
}


echo "# elrond_configs_rollup as of $(timestamp)" > "${rollup_file}"

for x in "${configs[@]}" ; do
  echo;
  echo $x;
  echo $(repeat '-' ${#x});
  grep -Ev --color=auto "(^\s*$|^#)" 2>/dev/null $x;
done >> "${rollup_file}" || die "failed to roll up configs"

cat "${rollup_file}"

bremoji $hammer
message "now transferring ${rollup_file} to ${target} with scp ..."
sudo -u ${user} scp "${rollup_file}" "${target}"  || die "failed to scp rollup to ${target}"

bremoji $face_beam
echo -e "${BGon}Success${Boff}"
