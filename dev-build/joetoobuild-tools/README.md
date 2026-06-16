Instructions for use in building a gentoo (joetoo) system:<br>
<b>(1)</b> boot the device from a Gentoo liveUSB or liveCD image
<b>(2)</b> follow the Gentoo handbook up through preparation of the disks to lay out storage for your new system (assumed to be mounted at /mnt/gentoo in these instructions). Note that you can tune and use the mount-the-rest tool from joetoobuild-tools to mount all LVs in an lvm on LUKS system... then continue --<br>
    cd /mnt/gentoo<br>
<b>(3)(a)</b> download the tarball for the joetoobuild-tools project --<br>
    wget https://raw.githubusercontent.com/JosephBrendler/myUtilities/master/dev-build/joetoobuild-tools-0.0.5.tbz2<br>
<b>(3)(b)</b> extract content to the root of your new system (probably /mnt/gentoo/<br>
    tar -xvjpf joetoobuild-tools-0.0.7.tbz2 -C /mnt/gentoo/<br>
<b>(4)</b> download script_header_joetoo and its helpers script_header_joetoo_compat and script_header_joetoo_unicode and move them to the livecd's /usr/sbin/directory<br>
    wget https://raw.githubusercontent.com/JosephBrendler/myUtilities/master/dev-util/script_header_joetoo<br>
    wget https://raw.githubusercontent.com/JosephBrendler/myUtilities/master/dev-util/script_header_joetoo_compat<br>
    wget https://raw.githubusercontent.com/JosephBrendler/myUtilities/master/dev-util/script_header_joetoo_unicode<br>
    mv script_header_joetoo* /usr/sbin<br>
<b>(5)</b> You can use the joetoobuild-tools "content_for_" file structures to have the joetoo-system-install script load custom or sensitive personal content (like ssh keys, etc) by populating the file system tree in directories pointed to by the script's mkenv_files and mkimg_files directories; examples are provided by the script, and the dev-sbc/collect-system-files package at https://github.com/JosephBrendler/myUtilities/tree/master/dev-sbc/collect-system-files can automate the collection of such information from existing systems (enabling fast rebuild)
<b>(6)</b> run the joetoo-system-install program (located in /mnt/gentoo/joetoobuild-tools/<br>
    Important: tune the script to ensure it selects and downloads a stage3 tarball matching the profile you intend to use.  Note: if you intend to use joetoo's hardened desktop profile, start by downloading the Gentoo hardened openrc stage3 tarball, and switch to joetoo's hardened-desktop profile after installation<br>
<b>(7)</b> when joetoo-system-install is complete, run the chroot-prep script, then
    run cat chroot-commands and copy/paste the lines of its output into the
    command line to execute them in line<br>
<b>(8)</b> note that when you chroot into your system, the /root/.bashrc provided by
    joetoo-system-install should automatically run the finalize-chroot-joetoo
    script it also provided in /usr/sbin<br>
<b>(9)</b> afterward, you may still need to build a kernel and bootloader
    (for amd64 systems, you should have a gentoo-kernel if you populated
     a savedconfig, but you will still need to install grub and run grub-mkconfig.
     note that if you use a custom initramfs, you will also have to install
     that before rebooting)<br>
