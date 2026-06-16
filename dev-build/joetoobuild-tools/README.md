Instructions for use in building a gentoo (joetoo) system:<br>
(1) boot the device from a Gentoo liveUSB or liveCD image
(2) follow the Gentoo handbook up through preparation of the disks to lay out storage for your new system (assumed to be mounted at /mnt/gentoo in these instructions). Note that you can tune and use the mount-the-rest tool from joetoobuild-tools to mount all LVs in an lvm on LUKS system... then continue --
    cd /mnt/gentoo
(3)(a) download the tarball for the joetoobuild-tools project --
    wget https://raw.githubusercontent.com/JosephBrendler/myUtilities/master/dev-build/joetoobuild-tools-0.0.5.tbz2
(3)(a) extract content to the root of your new system (probably /mnt/gentoo/
    tar -xvjpf joetoobuild-tools-0.0.7.tbz2 -C /mnt/gentoo/
(4)(a) download script_header_joetoo and its helpers script_header_joetoo_compat and script_header_joetoo_unicode and move them to the livecd's /usr/sbin/directory
    wget https://raw.githubusercontent.com/JosephBrendler/myUtilities/master/dev-util/script_header_joetoo
    wget https://raw.githubusercontent.com/JosephBrendler/myUtilities/master/dev-util/script_header_joetoo_compat
    wget https://raw.githubusercontent.com/JosephBrendler/myUtilities/master/dev-util/script_header_joetoo_unicode
    mv script_header_joetoo* /usr/sbin
(5) run the joetoo-system-install program (located in /mnt/gentoo/joetoobuild-tools/
    Important: tune the script to ensure it selects and downloads a stage3 tarball matching the profile you intend to use.  Note: if you intend to use joetoo's hardened desktop profile, start by downloading the Gentoo hardened openrc stage3 tarball, and switch to joetoo's hardened-desktop profile after installation
(6) when joetoo-system-install is complete, run the chroot-prep script, then
    run cat chroot-commands and copy/paste the lines of its output into the
    command line to execute them in line
(7) note that when you chroot into your system, the /root/.bashrc provided by
    joetoo-system-install should automatically run the finalize-chroot-joetoo
    script it also provided in /usr/sbin
(8) afterward, you may still need to build a kernel and bootloader
    (for amd64 systems, you should have a gentoo-kernel if you populated
     a savedconfig, but you will still need to install grub and run grub-mkconfig.
     note that if you use a custom initramfs, you will also have to install
     that before rebooting)
