#!/bin/bash
source /usr/sbin/script_header_joetoo

#-----[ variables ]--------------------------------------------------------------------------

PN=${0##*/}   #  like =$(basename $0) but w/o subshell and function call

if [ -f /etc/joetoolkit/BUILD ]; then . /etc/joetoolkit/BUILD; else BUILD="0.0.1"; fi

[ -z $verbosity ] && verbosity=${notice}  # assign default if null; allow calling program to dictate

runlevel="${2:-default}"

#-----[ functions ]--------------------------------------------------------------------------

my_usage() {
  j_msg -${err} "${BRon}usage${Boff}: ${_func_color}$PN${Boff} ${Con}<cmd>${Boff}"
  j_msg -${notice} -p "${BCon}Purpose: List dependencies of rc-services${Boff}"
  j_msg -${notice} -p "${BYon}Command line options --"
  j_msg -${notice} -m "  ${BWon}arg string(s) listing one or more rc-service names${Boff} (or one of the following)"
  j_msg -${notice} -m "  ${BMon}-r ${Boff}${Bon}[runlevel] ${BCon}(runlevel)${Boff}${Con} all services in runlevel (default is default)${Boff}"
  j_msg -${notice} -m "  ${BMon}-a ${Boff}${Bon}.......... ${BCon}(all)${Boff}${Con}} all services in all runlevels)${Boff}"
  j_msg -${notice} -m "  ${BMon}-d ${Boff}${Bon}.......... ${BCon}(default)${Boff}${Con} use default list (common joetoo router services)${Boff}"
  j_msg -${notice} -m "  ${BMon}-h ${Boff}${Bon}.......... ${BCon}(help)${Boff}${Con} print this message${Boff}"

  exit 1

}

parse_cmdline() {
  # parse command line
  case "$1" in
    -h) j_msg -${err} "provide one or more rc-service names to check"; exit 1 ;;
    -d) service_list=(
        sysklogd
        stubby
        dnsmasq
        shorewall
        shorewall6
        net.br0
        net.eth0
        node_exporter
        prometheus
        grafana
      )
      ;;
    -a) readarray -t service_list < <(rc-status --all | grep -v ':'  | sed "s|^${W0}||" | awk '{print $1}') ;;
    -r) [ ! -d "/etc/runlevels/${runlevel}" ] && my_usage;
      readarray -t service_list < <(rc-status "$runlevel" | grep -v ':'  | sed "s|^${W0}||" | awk '{print $1}') ;;
    *) service_list=("$@") ;;  # this is canonical "load positional parameters into bash array"
  esac


}
#-----[ main script ]--------------------------------------------------------------------------
checkroot
[ $# -eq 0 ] && { j_msg -${err} "${BRon}(error)${Boff} provide cmd option flag or one or more rc-service names to check" ; my_usage ; }
  separator "$(hostname)" "${PN}-${BUILD}"

parse_cmdline "$@"

for x in "${service_list[@]}"; do
  if [ ! -x "/etc/init.d/$x" ]; then
    j_msg -${err} "no init.d script found for $x; skipping"
    continue
  fi
  separator "${PN}-${BUILD}" "($x dependencies)"
  j_msg -${notice} -p -n "(${BYon}ineed${Boff}) ";  "/etc/init.d/$x" ineed;
  j_msg -${notice} -p -n "(${BGon}iwant${Boff}) ";  "/etc/init.d/$x" iwant;
  j_msg -${notice} -p -n "(${BBon}iafter${Boff}) "; "/etc/init.d/$x" iafter;
  j_msg -${notice} -p -n "(${BCon}iuse${Boff}) ";   "/etc/init.d/$x" iuse;
done
