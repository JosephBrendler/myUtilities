#!/bin/bash
[[ ! $# -eq 2 ]] && echo "useage: resize_xen_image.sh <imagefilename> <newsizeinGB>" && exit 1
[[ ! -f $1 ]] && echo "image file not found" && exit 1
IMAGE=$1
SIZE=$2
echo "copying ${IMAGE} to ${IMAGE}.backup, just in case..."
cp -a ${IMAGE} ${IMAGE}.backup
[[ ! $? ]] && echo "backup copy operation failed" && exit 1
echo "running e2fsck"
e2fsck ${IMAGE}
[[ ! $? ]] && echo "precursory e2fsck failed" && exit 1
echo "writing with dd"
dd if=/dev/zero of=${IMAGE} bs=1024k count=1 seek=${SIZE}k
[[ ! $? ]] && echo "dd write failed" && exit 1
echo "running resize2fs"
resize2fs ${IMAGE} ${SIZE}G
[[ ! $? ]] && echo "resize2fs failed" && exit 1
echo "running e2fsck"
e2fsck -pf ${IMAGE}
[[ ! $? ]] && echo "confirmational e2fsck failed" && exit 1
