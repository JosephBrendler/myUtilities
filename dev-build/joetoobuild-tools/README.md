Instructions for use in building a gentoo (joetoo) system:
(1) boot the device from a Gentoo liveUSB image
(2) follow the Gentoo handbook up through preparation of the disks to lay out your new system
(3) clone (this) the joetoobuild-tools project folder from the myUtilities repository
    git clone https://placeholderforurl/joetoobuild-tools.git
    (this should download the joetoo-system-install script and several supporting files
    (you will need to provide the content for content-for-mkimg... which contains sensitive info
     like private keys that should not be uploaded to github)
(4) run the joetoo-system-install program 
    (ensure the sript downloads a stage3 tarball matching the profile you intend to use)
(5) when joetoo-system-install is complete, run the chroot-prep script, then
    run cat chroot-commands and copy/paste the lines of its output into the
    command line to execute them in line
(6) note that when you chroot into your system, the /root/.bashrc provided by
    joetoo-system-install should automatically run the finalize-chroot-joetoo
    script it also provided in /usr/sbin
(7) afterward, you may still need to build a kernel and bootloader
    (for amd64 systems, you should have a gentoo-kernel if you populated
     a savedconfig, but you will still need to install grub and run grub-mkconfig.
     note that if you use a custom initramfs, you will also have to install
     that before rebooting)
