#!/bin/bash
. /usr/sbin/script_header_joetoo
PN=${0##*/}   # basename

usage() {j_msg -${err} "useage: ${PN} <imagefilename> <newsizeinGB>" && exit 1 ; }

[[ ! $# -eq 2 ]] && { j_masg -${err} "Error: too many args"; usage ; }
[[ ! -f $1 ]] && { j_msg -${err} "image file not found"; usage ; }

IMAGE=$1
SIZE=$2

j_msg -${notice} -p "copying ${IMAGE} to ${IMAGE}.backup, just in case..."
cp -a ${IMAGE} ${IMAGE}.backup
j_msg -${notice} -m -n "done; result:"
right_status $? ${notice} || die "backup copy operation failed"

j_msg -${notice} -p "running e2fsck"
e2fsck ${IMAGE}
j_msg -${notice} -m -n "done; result:"
right_status $? ${notice} || die "precursory e2fsck failed"

j_msg -${notice} -p "writing with dd"
dd if=/dev/zero of=${IMAGE} bs=1024k count=1 seek=${SIZE}k
j_msg -${notice} -m -n "done; result:"
right_status $? ${notice} || die "dd write failed"

j_msg -${notice} -p "running resize2fs"
resize2fs ${IMAGE} ${SIZE}G
j_msg -${notice} -m -n "done; result:"
right_status $? ${notice} || die "resize2fs failed"

j_msg -${notice} -p "running e2fsck"
e2fsck -pf ${IMAGE}
j_msg -${notice} -m -n "done; result:"
right_status $? ${notice} || die "confirmational e2fsck failed" && exit 1
