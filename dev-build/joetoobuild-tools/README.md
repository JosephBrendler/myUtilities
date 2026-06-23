<b>Instructions for use in building a joetoo (gentoo) system:</b><br><br>

<b>(1)(a)</b> Boot the device from a Gentoo liveUSB or liveCD image<br>
<code>passwd</code><br>
<code>/etc/init.d/sshd start</code><br>
<code>ip addr show | grep 'scope global'</code><br>
<b>(1)(b)</b> (from a workstation)<br>
<code>ssh root@<ip_address></code><br><br>

<b>(2)</b> Follow the Gentoo handbook up through preparation of the disks to lay out storage for your new system (assumed to be mounted at /mnt/gentoo in these instructions)<br>
<b>Example:</b><br>
<code>cryptsetup luksOpen /dev/sdc2 edc2</code><br>
<code>mount /dev/mapper/vg_barracuda-root /mnt/gentoo/</code><br>
<code>cd /mnt/gentoo</code><br><br>

<b>(3)(a)</b> Download the tarball for the joetoobuild-tools project --<br>
    <code>wget https://raw.githubusercontent.com/JosephBrendler/myUtilities/master/dev-build/joetoobuild-tools-0.0.9.tbz2</code><br>
    (Note: browse first, identify, and download the latest version of the package tarball)<br>
<b>(3)(b)</b> Extract content to the root of your new system (probably /mnt/gentoo/<br>
    <code>tar -xvjpf joetoobuild-tools-0.0.9.tbz2 -C /mnt/gentoo/</code><br>
<b>(3)(c)</b> tune and use the mount-the-rest.template tool from joetoobuild-tools<br>
(this facilitates mounting all parts of your target filesystem, which can be tedious without automation like this if you have a mix of partitions and LVs in an lvm on LUKS system, for example)<br>
To tune mount-the-rest.template for your system, edit and change the value assigned to variables root_vg, boot_partuuid, and efi_uuid as applicable, and rename the now-unique file something like mount-the-rest.hostname (with the hostname you intend to give the new system)<br>
<code>cp /mnt/gentoo/joetoobuild-tools/mount-the-rest.template ./mount-the-rest.hostname</code><br>
Then run --<br>
<code>./mount-the-rest.hostname</code>
(which will mount volumes and report what was mounted)<br><br>

<b>(4)</b> The next step will be to run the jb-mksys script (called joetoo-system-install in earlier versions of this package but renamed for functional consistency with elements of the dev-sbc/crossbuild-tools package), but you may first want to prepare the custom content trees the script can use to populate the system tree beyond what comes with the stage3 tarball it will extract for you.<br>
You can use the joetoobuild-tools "content_for_" file structures (identical to similarly named structures used in the crossbuild-tools toolset) to have the jb-mksys script load custom or sensitive personal content (like ssh keys, openvpn, and/or apache ssl certificates, etc) by populating the file system tree in directories pointed to by the script's mkenv_files and mkimg_files directories.<br>
<b>mkenv_files</b> - generic content that should be found on any joetoo system using this hardware platform<br>
<b>mkimg_files</b> - content unique to this particular system and potentially sensitive as described above - stuff you would not want to upload to a public repository<br>
(Examples are provided by the package)
Use the <b>dev-sbc/collect-system-files</b> package at https://github.com/JosephBrendler/myUtilities/tree/master/dev-sbc/collect-system-files to automate the collection of such information from existing systems (enabling fast rebuild)<br>
<code>eselect collect-system-files list/set</code><br>
<code>nano /etc/collect-system-files/collect-system-files.conf</code><br>
<code>collect-system-files -N</code><br>
(it will automate the collection of directories and file, and it will transfer the packaged tree with rsync over user ssh to destination workstations according to the .conf.  If you connected via ssh as described in step 1 above, you can also use scp to transfer this content to your target system<br>
<code>scp content_for_mkimg_hostname root@<ip_address>:/mnt/gentoo/joetoobuild-tools/</code><br>

<b>(5)</b> Run the <b>jb-mksys</b> script (located in /mnt/gentoo/joetoobuild-tools/)<br>
<b>Important:</b> you should tune the script to ensure it selects and downloads a stage3 tarball matching the profile you intend to use.  E.g. if you intend to use joetoo's hardened desktop profile, start by downloading the Gentoo hardened openrc stage3 tarball, and switch to joetoo's hardened-desktop profile after installation<br>
<code>STAGE3_SELECTOR='stage3-amd64-hardened-openrc-[0-9]'<br>
./jb-mksys</code><br><br>

<b>(6)</b> When jb-mksys is complete, you are basically ready to chroot<br>
jb-mksys's last action is to display a "next_steps" message advising you to edit root's .bashrc and the new /etc/portage/make.conf file before chrooting and that you can re-print those instructions from a file at any time, if you like.<br>
You can chroot into the new system two ways - either using the jb-chroot-sys tool or manually.  If you choose to chroot manually, you can still use the package's chroot-prep command to mount things and cat the chroot-commands file to list (and copy / paste) the commands used to actually execute the chroot<br>
<code>./jb-chroot-sys</code>  (or)<br>
<code>./chroot-prep</code><br>
<code>cat ./chroot-commands<br>
</code>
(copy/paste the chroot command in the terminal command line)<br>
<code>livecd /mnt/gentoo/joetoobuild-tools # env -i chroot /mnt/gentoo /bin/bash</code><br>
<code>livecd / # source /etc/profile</code><br>
<code>livecd / # export PS1="(chroot) $PS1"</code>br>
<code>(chroot) livecd / #</code><br><br>

<b>(7)</b> When you chroot into your system, the /root/.bashrc provided by
    joetoo-system-install will automatically run the finalize-chroot-joetoo
    script it also provided in the target system /usr/sbin<br><br>

<b>(8)</b> Afterward, you may still need to build a kernel and bootloader
    (for amd64 systems, you should have a gentoo-kernel if you populated
     a savedconfig, but you will still need to install grub and run grub-mkconfig.
     note that if you use a custom initramfs, you will also have to install
     that before rebooting)<br><br>
     
<b>(9)</b> If you need to iterate parts of the build process, these tools may be helpful --<br>
<code>umount-chroot</code> - commands needed to umount and comments about how to deal w possible "busy" error<br>
<code>jb-reformat-LVs</code> - after un-mounting LVs, this will reformat some or all of them<br>
Then remount the root LV as in step 2 above, and use <code>jb-prune-root</code> if you want to preserve some content (such as joetoobuild-tools and the custom content you want it to load) on the root LV, then use <code>reformat_joetoo_LVs --all-but-root</code>, and then use <code>prune_joetoo_root</code> (which defaults to --dry-run) to delete non-whitelisted content on the root LV<br>
(edit the script to tune the whitelist, and then use e.g. <code>../mount-the-rest.hostname</code> to re-mount the rest of the new system's filesystem, and begin again with <b>jb-mksys</b><br><br>

<b>Summary of reset</b><br>
(example run from livecd /mnt/gentoo/joetoobuild-tools # on new system "retro")<br>
<code>umount -R /mnt/gentoo/* 2>/dev/null<br>
./jb-reformat-LVs --all-but-root<br>
./jb-prune-root --go<br>
../mount-the-rest.retro <br>
./jb-mksys<br><br>
</code><br><br>

<b>Complete build-reset on one line:</b><br>
<code>umount -R /mnt/gentoo/* 2>/dev/null; ./jb-reformat-LVs --all-but-root; ./jb-prune-root --go; ../mount-the-rest.retro</code><br><br>

<b>Note:</b> If you reboot the livecd, you will need to resume the process at step (2) above, but you will not need to repeat step 3 if you whitelisted that content when using jb-prune-root.<br> Mount the root device at /mnt/gentoo; mount the rest of the LVs; and then run joetoo-system-install<br><br>

<b>Note:</b> if you need to download content from other repositories, this technique works --
<b>(*)</b> download script_header_joetoo --<br>
    <code>wget https://raw.githubusercontent.com/JosephBrendler/myUtilities/master/dev-util/script_header_joetoo/script_header_joetoo</code><br>


