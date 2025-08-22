collect-system-files replaces dev-sbc/crossbuild-tools
internal tools cb-collect-basic and cb-collect-sensitive with a
separate collect-system-files tool in the eponymous package
dev-util/collect-system-files

vision:
someday, dev-sbc/crossbuild-tools may be generalized to build not just
SBCs and generic amd systems, but any number of named amd64 boards as
well, and at that time, it should become dev-build/joetoo-build-tools

Use case (1): dev-sbc/crossbuild-tools is designed to run on a build-host;
not on every workstation and platform.  Separating this package as
dev-util/collect-system-files will allow dev-sbc/crossbuild-tools users
to deploy just the needed "collect-system-files" tool to platforms from
which data sensitive data should be collected, so these systems can be
re-built with a state-of-art stage3.  This is particularly important for
small/slow/small-memory systems that would take way too long to compile
updates to large packages like gcc, llvm, etc. (it should be faster to
just re-build them when the new versions need to be deployed). Such users
should point the collect-system-files.conf symlink at a configuration
file like collect-system-files_sensitive.conf

Use case (2): developers of dev-sbc/crossbuild-tools need to populate the
file system tree at mkenv-files with the system files common accross
joetoo systems.  Templates for these files should be collected from
time to time, to update the dev-sbc/crossbuild-tools package as these
basic joetoo system files evolve.  Such users should point the
collect-system-files.conf symlink at a configuration file like
collect-system-files_basic.conf
