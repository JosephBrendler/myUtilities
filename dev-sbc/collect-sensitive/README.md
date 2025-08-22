starting 8/22/2025, cb-collect-sensitive is removed from dev-sbc/crossbuild-tools
to become a separate package dev-util/collect-sensitive

vision:
someday, dev-sbc/crossbuild-tools may be generalized to build not just
SBCs and generic amd systems, but any number of named amd64 boards as
well, and at that time, it should become dev-util/build-tools

In any case, dev-sbc/crossbuild-tools is designed to run on a build-host;
not on every workstation and platform.  Separating this package as
dev-util/collect-sensitive will allow dev-sbc/crossbuild-tools users
to deploy just the needed "collect-sensitive" tool to platforms from
which data sensitive data should be collected, so these systems can be
re-build with a state-of-art stage3

This is particularly important for small/slow/small-memory systems
that would take way too long to compile updates to large packages
like gcc, llvm, etc. (it should be faster to just re-build them when
the new versions need to be deployed)

