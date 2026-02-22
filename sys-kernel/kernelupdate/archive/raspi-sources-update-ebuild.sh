#!/bin/bash
# this script will update and ebuild to deploy kernes built with this version
# follow README_raspi-sources_instructions
# Note: this is for raspi-sources only -- rockchip-sources ebuilds don't have
#   to be updated like this - they just have to be copied to a new-versioned
#   name with no change to internal content
#
# Also review this: https://www.raspberrypi.com/documentation/computers/linux_kernel.html
#

source /usr/sbin/script_header_joetoo
BUILD=0.0.01a
VERBOSE=$TRUE
verbosity=3

newbranch="$1"

PN="raspi-sources"
local_repodir=/home/${user}/${PN}/
ebuild_dir="/home/${user}/joetoo/sys-kernel/${PN}"

#initialize other variables
newbranch=""
newversion=""
newcommit=""
oldbranch=""
oldversion=""
oldcommit=""

#-----[ functions (run as user) ]-------------------------------------------
usage() {
E_message "usage:  update-ebuild.sh <newbranch>"
message "example ./update-ebuild.sh rpi-6.7.y"
message "Note: <newbranch> always ends in '.y' "
exit
}

update_sources() {
  # move to the local git respository (raspi-sources), and refresh or install (linux)
  old_dir="$(pwd)"
  # move to the parent-directory of the repository
  cd ${local_repodir}
  if [ -d ./linux ]
  then
    # move into the repository and refresh it
    cd linux
    echo "now in $(pwd)..."
  else
    echo "sources folder [ ${local_repodir}/linux ] does not exist. cloning it..."
    # clone the repository
    git clone --depth 1 --branch $1 https://github.com/raspberrypi/linux.git
    # move into the repository
    cd linux
  fi

  # check out the new branch

  # assign new branch, version, and commit ID variables (of new head commit for this branch)
  echo "Now working in pwd = $(pwd)"
#  newbranch=$(git status | head -n1 | awk '{print $3}')  ### this way for full clone
  newbranch="$1"
  newversion=$(make kernelversion)
  newcommit=$(git log | head -n1 | cut -d' ' -f2)
}

update_ebuild() {
  # get and store the old (latest previously-installed-ebuild) version, branch, and commit
  latest="0.0.0"
  for x in $(find ${ebuild_dir}/ -iname "${PN}-*")
  do
    this=$(qatom -F %{PV} $x)
    vercomp "$this" "$latest"  # returns 0 if =, 1 if >; 2 if <
    [ $? -eq 1 ] && latest="$this"
  done
  oldversion="$latest"
  eval $(grep EGIT_BRANCH ${ebuild_dir}/${PN}-${oldversion}.ebuild | grep -v einfo | grep -v '^#')
  oldbranch=${EGIT_BRANCH}
  eval $(grep EGIT_COMMIT ${ebuild_dir}/${PN}-${oldversion}.ebuild | grep -v einfo | grep -v '^#')
  oldcommit=${EGIT_COMMIT}

  # display this info
  echo "oldversion..: ${oldversion}"
  echo "newversion..: ${newversion}"
  echo "oldbranch...: ${oldbranch}"
  echo "newbranch...: ${newbranch}"
  echo "oldcommit...: ${oldcommit}"
  echo "newcommit...: ${newcommit}"

  # copy the latest ebuild, to create new ebuild with ${newversion}
  cp ${ebuild_dir}/${PN}-${oldversion}.ebuild ${ebuild_dir}/${PN}-${newversion}.ebuild

  # edit the new ebuild to replace the EGIT_BRANCH and EGIT_COMMIT values
  sed -i "s|${oldbranch}|${newbranch}|g" ${ebuild_dir}/${PN}-${newversion}.ebuild
  sed -i "s|${oldcommit}|${newcommit}|g" ${ebuild_dir}/${PN}-${newversion}.ebuild

  # move to the ebuild dir in the joetoo repository
  cd ${ebuild_dir}
  # update the manifest
  rm -fv Manifest
  pkgdev manifest -f
  # git pull first just in case we need to sync up
  git pull
  # add, commit, and push the change to the joetoo repository
  git status
  git add Manifest
  git add ../../metadata/md5-cache/sys-kernel/raspi-sources-${newversion}
  git add raspi-sources-${newversion}.ebuild
  git commit -m "adding ebuild for ${PN}-${newversion}"
  git push origin master

  # now return to original directory
  cd ${old_dir}
}

#-----[ main script ]-------------------------------------
separator "update-ebuild.sh-$BUILD"
checknotroot

[ $# -ne 1 ] && usage
update_sources "$1"
update_ebuild "$1"

