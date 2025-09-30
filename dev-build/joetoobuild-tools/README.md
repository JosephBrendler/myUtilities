Instructions for use in building a gentoo (joetoo) system:
(1) boot the device from a Gentoo liveUSB image
(2) follow the Gentoo handbook up through preparation of the disks to lay out your new system
(3) download the tarball for the joetoobuild-tools project --
     wget https://raw.githubusercontent.com/JosephBrendler/myUtilities/master/dev-build/joetoobuild-tools-0.0.5.tbz2
(4) extract content to the root of your new system (probably /mnt/gentoo/
     tar -xvjpf joetoobuild-tools-0.0.5.tbz2 -C /mnt/gentoo/
(5) run the joetoo-system-install program 
    (ensure the sript downloads a stage3 tarball matching the profile you intend to use)
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
