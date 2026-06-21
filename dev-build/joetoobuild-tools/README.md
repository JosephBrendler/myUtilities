<b>Instructions for use in building a joetoo (gentoo) system:</b><br><br>

<b>(1)(a)</b>boot the device from a Gentoo liveUSB or liveCD image<br>
<code>passwd</code><br>
<code>/etc/init.d/sshd start</code><br>
<code>ip addr show | grep 'scope global'</code><br>
<b>(1)(b)</b> (from a workstation) <code>ssh root@<ip_address></code><br><br>

<b>(2)</b> follow the Gentoo handbook up through preparation of the disks to lay out storage for your new system (assumed to be mounted at /mnt/gentoo in these instructions)<br>
<b>Example:</b><br>
<code>cryptsetup luksOpen /dev/sdc2 edc2</code><br>
<code>mount /dev/mapper/vg_barracuda-root /mnt/gentoo/</code><br>
<code>cd /mnt/gentoo</code><br><br>

<b>(3)(a)</b> download the tarball for the joetoobuild-tools project --<br>
    <code>wget https://raw.githubusercontent.com/JosephBrendler/myUtilities/master/dev-build/joetoobuild-tools-0.0.9.tbz2</code><br>
    (Note: browse first, identify, and download the latest version of the package tarball)<br>
<b>(3)(b)</b> extract content to the root of your new system (probably /mnt/gentoo/<br>
    <code>tar -xvjpf joetoobuild-tools-0.0.9.tbz2 -C /mnt/gentoo/</code><br>
<b>(3)(c)</b> tune and use the mount-the-rest.template tool from joetoobuild-tools to mount all LVs in an lvm on LUKS system<br>
<code>cp /mnt/gentoo/joetoobuild-tools/mount-the-rest.template ./mount-the-rest.hostname</code><br>
(edit and change the value assigned to variables root_vg, boot_partuuid, and efi_uuid as applicable to your system)<br>
<code>./mount-the-rest.hostname</code>
(it will mount volumes and report what it mounted)<br><br>

<b>(4)</b> The next step is to run the joetoo-system-install script, but you may first want to prepare the custom content trees the script will use to populate the system tree beyond what comes with the stage3 tarball it will extract for you.<br>
You can use the joetoobuild-tools "content_for_" file structures to have the joetoo-system-install script load custom or sensitive personal content (like ssh keys, etc) by populating the file system tree in directories pointed to by the script's mkenv_files and mkimg_files directories; examples are provided by the script, and the <b>dev-sbc/collect-system-files</b> package at https://github.com/JosephBrendler/myUtilities/tree/master/dev-sbc/collect-system-files can automate the collection of such information from existing systems (enabling fast rebuild)<br>
<code>eselect collect-system-files list/set<br>
nano /etc/collect-system-files/collect-system-files.conf<br>
collect-system-files -N<br>
</code>
(it will automate the collection of directories and file, and it will transfer the packaged tree with rsync over user ssh to destination workstations according to the .conf)<br><br>

<b>(5)</b> run the <b>joetoo-system-install</b> script (located in /mnt/gentoo/joetoobuild-tools/<br>
<b>Important:</b> you can tune the script to ensure it selects and downloads a stage3 tarball matching the profile you intend to use.  E.g. if you intend to use joetoo's hardened desktop profile, start by downloading the Gentoo hardened openrc stage3 tarball, and switch to joetoo's hardened-desktop profile after installation<br>
<code>STAGE3_SELECTOR='stage3-amd64-hardened-openrc-[0-9]'<br>
./joetoo-system-install</code><br><br>

<b>(6)</b> when joetoo-system-install is complete, you are ready to chroot<br>
<code>./chroot-prep<br>
cat ./chroot-commands<br>
</code>
You can copy/paste the chroot command in the terminal command line<br>
<code>env -i chroot /mnt/gentoo /bin/bash</code><br><br>

<b>(7)</b> When you chroot into your system, the /root/.bashrc provided by
    joetoo-system-install will automatically run the finalize-chroot-joetoo
    script it also provided in the target system /usr/sbin<br><br>

<b>(8)</b> afterward, you may still need to build a kernel and bootloader
    (for amd64 systems, you should have a gentoo-kernel if you populated
     a savedconfig, but you will still need to install grub and run grub-mkconfig.
     note that if you use a custom initramfs, you will also have to install
     that before rebooting)<br><br>
     
<b>(9)</b> If you need to iterate parts of the build process, these tools may be helpful --<br>
<code>umount-chroot</code> - commands needed to umount and comments about how to deal w possible "busy" error<br>
<code>reformat_joetoo_LVs</code> - after un-mounting LVs, this will reformat some or all of them<br>
Then remount the root LV as in step 2 above<br>
and use <code>prune_joetoo_root</code><br>
If you want to preserve some content (such as joetoobuild-tools and the custom content you want it to load) on the root LV, then use <code>reformat_joetoo_LVs --all-but-root</code>, and then use <code>prune_joetoo_root</code> (which defaults to --dry-run) to delete non-whitelisted content on the root LV<br>
(edit the script to tune the whitelist, and then use e.g. <code>../mount-the-rest.retro</code> to re-mount the rest of the new system's filesystem, and begin again with <b>joetoo-system-install</b><br><br>

<b>Summary of reset</b><br>
(example run from livecd /mnt/gentoo/joetoobuild-tools # on new system "retro")<br>
<code>umount -R /mnt/gentoo/* 2>/dev/null<br>
./reformat_joetoo_LVs --all-but-root<br>
./prune_joetoo_root --go<br>
../mount-the-rest.retro <br>
./joetoo-system-install<br><br>
</code><br><br>

<b>Complete build-reset on one line:</b><br>
<code>umount -R /mnt/gentoo/* 2>/dev/null; ./reformat_joetoo_LVs --all-but-root; ./prune_joetoo_root --go; ../mount-the-rest.retro</code><br><br>

<b>Note:</b> if you reboot the livecd, you will need to resume the process at step (2) above, but you will not need to repeat step 3 if you whitelisted that content when using prune_joetoo_root.<br> Mount the root device at /mnt/gentoo; mount the rest of the LVs; and then run joetoo-system-install<br><br>

<b>Note:</b> if you need to download content from other repositories, this technique works --
<b>(*)</b> download script_header_joetoo --<br>
    <code>wget https://raw.githubusercontent.com/JosephBrendler/myUtilities/master/dev-util/script_header_joetoo/script_header_joetoo</code><br>


