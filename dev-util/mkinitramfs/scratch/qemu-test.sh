#!/bin/bash

source /usr/sbin/script_header_joetoo
checkroot
checkboot

#-----[ variables ]---------------------------------------------------------------
keydev="/dev/disk/by-label/KEY"    # this is the partition we need/guard for (should protect both the .img and sda1)

keydev_disk="qemu_usbkey.img"      # keydev image file for testing

root_vg="vg_rock5bplus6401"        # this is the test usb|nvme stick

luks_partition_device="/dev/sdb2"  # this is how gmki91 identifies the usb|nvme stick
luks_disk="/dev/sdb"               # this is what I will try to pass to qemu so a parittion comes out on top of it

#current_kernel="/boot/vmlinuz-6.12.63-gentoo-dist-hardened-joetoo"
current_kernel="/boot/vmlinuz-6.12.68-gentoo-dist-hardened-joetoo"
#initramfs_img="boot/initramfs-6.12.63-202602010135"
initramfs_img="boot/initramfs.latest"

#q_verbosity="$info"
q_verbosity="$debug"

#-----[ functions ]---------------------------------------------------------------

is_keydev_safe() {
    # Returns true if NOT mounted
    ! findmnt "$keydev" >/dev/null
}

is_vg_safe() {
    # Returns true if VG is NOT active ("a")
    ! vgs "$root_vg" --noheadings 2>/dev/null | grep -q "a"
}

is_luks_safe() {
    # Returns true if partition does NOT have an active "crypt" holder
    ! lsblk "$luks_partition_device" | grep -q "crypt"
}

#-----[ main script ]------------------------------------------------------------

if is_keydev_safe && is_vg_safe && is_luks_safe; then
  notice_msg "guardrails satisfied, starting qemu-system-x86_64 ..."
  notice_msg "${BYon}use ${BRon}CTRL-a x ${BYon}to get back to the terminal${Boff}"
  echo
  sh_countdown 2
  # use qemu-system-x86_64 to emulate the boot environment for initramfs testing
  # construct an array to hold this complex command
  qemu_cmd=(
    qemu-system-x86_64
    -enable-kvm       # Enables hardware acceleration (REQUIRED for -cpu host)
    -cpu host         # Passes through my actual hardware [gmki91: Alder Lake flags (AVX2, AES, etc.)]
    -m "2G"
    -kernel "${current_kernel}"
    -initrd "${initramfs_img}"
    -append "console=ttyS0 root=/dev/mapper/${root_vg}-root verbosity=${q_verbosity}"
    -drive "file=${luks_disk},format=raw,if=ide,cache=none"
    -device "usb-ehci,id=usb"
    -drive "file=${keydev_disk},format=raw,if=none,id=usbkey,readonly=on"
    -device "usb-storage,bus=usb.0,drive=usbkey"
    -nographic
)
#    -drive "file=${luks_partition_device},format=raw,if=virtio,cache=none"

  # execute the array
  "${qemu_cmd[@]}" | tee boot/qemu_boot.log
  stty sane  # restore terminal state to sane defaults in case command crashed
else
  error_msg "error: ensure /dev/sda1 and vg_rock5bplus6401 are not in use"
fi
