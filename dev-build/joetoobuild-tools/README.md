Instructions for use in building a gentoo (joetoo) system:<br>
<b>(1)</b> boot the device from a Gentoo liveUSB or liveCD image
<b>(2)</b> follow the Gentoo handbook up through preparation of the disks to lay out storage for your new system (assumed to be mounted at /mnt/gentoo in these instructions). Note that you can tune and use the mount-the-rest tool from joetoobuild-tools to mount all LVs in an lvm on LUKS system... then continue --<br>
    cd /mnt/gentoo<br>
<b>(3)(a)</b> download the tarball for the joetoobuild-tools project --<br>
    wget https://raw.githubusercontent.com/JosephBrendler/myUtilities/master/dev-build/joetoobuild-tools-0.0.5.tbz2<br>
<b>(3)(b)</b> extract content to the root of your new system (probably /mnt/gentoo/<br>
    tar -xvjpf joetoobuild-tools-0.0.7.tbz2 -C /mnt/gentoo/<br>
<b>(4)</b> download script_header_joetoo and its helpers script_header_joetoo_compat and script_header_joetoo_unicode and move them to the livecd's /usr/sbin/directory<br>
    wget https://raw.githubusercontent.com/JosephBrendler/myUtilities/master/dev-util/script_header_joetoo/script_header_joetoo<br>
    wget https://raw.githubusercontent.com/JosephBrendler/myUtilities/master/dev-util/script_header_joetoo/script_header_joetoo_compat<br>
    wget https://raw.githubusercontent.com/JosephBrendler/myUtilities/master/dev-util/script_header_joetoo/script_header_joetoo_unicode<br>
<b>(5)(a)</b> also download script_header_joetoo_extended and copy it to /usr/sbin/ to enable its run_array() functionality - automating the command sequences in joetoo-system-install and finalize-chroot-joetoo
    wget https://raw.githubusercontent.com/JosephBrendler/myUtilities/master/dev-util/script_header_joetoo/script_header_joetoo_extended<br>
<b>(5)(b)</b>copy the script_header files to the cannonical location in PATH --<br>
cp script_header_joetoo* /usr/sbin/<br>
<b>(6)</b> You can use the joetoobuild-tools "content_for_" file structures to have the joetoo-system-install script load custom or sensitive personal content (like ssh keys, etc) by populating the file system tree in directories pointed to by the script's mkenv_files and mkimg_files directories; examples are provided by the script, and the dev-sbc/collect-system-files package at https://github.com/JosephBrendler/myUtilities/tree/master/dev-sbc/collect-system-files can automate the collection of such information from existing systems (enabling fast rebuild)
<b>(7)</b> run the joetoo-system-install program (located in /mnt/gentoo/joetoobuild-tools/<br>
    Important: tune the script to ensure it selects and downloads a stage3 tarball matching the profile you intend to use.  Note: if you intend to use joetoo's hardened desktop profile, start by downloading the Gentoo hardened openrc stage3 tarball, and switch to joetoo's hardened-desktop profile after installation<br>
<b>(8)</b> when joetoo-system-install is complete, run the chroot-prep script, then
    run cat chroot-commands and copy/paste the lines of its output into the
    command line to execute them in line<br>
<b>(9)</b> note that when you chroot into your system, the /root/.bashrc provided by
    joetoo-system-install should automatically run the finalize-chroot-joetoo
    script it also provided in /usr/sbin<br>
<b>(10)</b> afterward, you may still need to build a kernel and bootloader
    (for amd64 systems, you should have a gentoo-kernel if you populated
     a savedconfig, but you will still need to install grub and run grub-mkconfig.
     note that if you use a custom initramfs, you will also have to install
     that before rebooting)<br>
<b>(11)</b> If you need to iterate parts of the build process, these tools may be helpful --<br>
    <b>umount-chroot</b> - commands needed to umount and comments about how to deal w possible "busy" error<br>
    <b>reformat_joetoo_LVs</b> - after un-mounting LVs, this will reformat some or all of them<br>
    Then remount the root lv with e.g. <code>mount /dev/mapper/vg_barracuda-root /mnt/gentoo</code><br>
    and use <b>prune_joetoo_root</b> (if you want to preserve some content (such as joetoobuild-tools) on the root LV,
    and you used reformat_joetoo_LVs --all-but-root<br>
    Then use <b>prune_joetoo_root</b> (which defaults to --dry-run) to delete non-whitelisted content on the root LV<br>
    Then use e.g. <b>../mount-the-rest.retro</b> to re-mount the rest of the new system's filesystem,
    and begin again with <b>joetoo-system-install</b><br><br>

Summary of reset (example run from livecd /mnt/gentoo/joetoobuild-tools # on new system "retro"-<br>
umount -R /mnt/gentoo/* 2>/dev/null<br>
./reformat_joetoo_LVs --all-but-root<br>
./prune_joetoo_root --go<br>
../mount-the-rest.retro <br>
./joetoo-system-install<br><br>

Complete build-reset on one line:<br>
<code>umount -R /mnt/gentoo/* 2>/dev/null; ./reformat_joetoo_LVs --all-but-root; ./prune_joetoo_root --go; ../mount-the-rest.retro</code><br><br>

<b>Note:</b> if you reboot the livecd, you will need to resume the process at step (5)(b) above, copying script header files to /usr/sbin/; mount the root device at /mnt/gentoo; mount the rest of the LVs; and then run joetoo-system-install
