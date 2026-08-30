# myUtilities

`myUtilities` is the source-code repository for **joetoo**, a collection of tools, development resources, system-building automation, configuration utilities, and platform-support and script-development support software used to build and maintain joetoo/Gentoo Linux systems across multiple hardware architectures.

The corresponding ebuild repository supporting joetoo use of the Gentoo Portage package manager is [joetoo](https://github.com/JosephBrendler/joetoo).

## Purpose

This repository contains the upstream source for utilities that automate installation, configuration, building/cross-building, kernel management, system maintenance, and other tasks used throughout the joetoo environment.

Although the project began as a simple collection of personal Linux utilities, and grew to support automation infrastructure for building and operating ARM single-board computers, joetoo is evolving into a common platform-management architecture supporting SBC and conventional x86_64 systems across multiple architectures, including ARM, ARM64, and amd64/x86_64.

This source repository and the ebuild repository intentionally have the same directory structures reflecting the scope of category/package_name existent in joetoo:

```text
myUtilities                         joetoo
(sources)                            (ebiuilds)

dev-build/                          dev-build/
dev-sbc/                            dev-sbc/
dev-util/                           dev-util/
joetoo-base/                        joetoo-base/
sys-kernel/                         sys-kernel/
   ...                                 ...
`Note: Some of these categories (e.g. dev-sbc) do not exist in upstream Gentoo profiles, and are only defined in profiles maintained in the joetoo repository

A package in the `joetoo` repository may therefore install, configure, or otherwise consume software maintained here.

## Platform Architecture

Each joetoo installation has a hardware **board** identity used to resolve the properties needed to build and configure that system. dev-sbc/crossbuild-tools and dev-build/joetoobuild-tools packages include tools used to discover this board identity and its properties from existing systems and document that so that their other tools can use that information in the automated build processes they facilitate.

Historically board identity represented an SBC board (and only SBCs) directly by simply adopting the name of the device tree file (*.dtb) describing the board as the board name - e.g. meson-gxl-s905x-libretech-cc-v2 for the Libre Computer AML-S905X-CC V2 (SweetPotato) or bcm2712-rpi-cm5-cm5io for the Raspberry Pi Compute Module 5 Rev 1.0). The **board** abstraction is retained but expanded as applied for conventional x86_64 systems, where the corresponding hardware **platform** is effectively the populated motherboard: motherboard, processor/chipset, and other characteristics relevant to system construction. Because these systems universally support UEFI/BIOS, thus not requiring device tree support, there are no *.dtb files from with to name them.

Accordingly, joetoo retains existing `BOARD` terminology for hardware identification while conceptually using **platform** as the broader term for the environment resolved from that identity, and the board naming format adopted for x86_64 systems reflects this platform information - e.g. dell:skylake:optiplex-7040, mktec:alderlake-n:nucbox-g3, lattepanda:alderlake-n:lattepanda-iota, or even asus:amd-k8-athlon-x2:a8n-sli-premium.

Note: transition ongoing to efolve joetoo from "SBC and generic x86_64" support to the framework described above.

Conceptually, this board name describing the platform via the format <vendor>:<cpu_class>:<board_model> provides a unique description of the platform and its constituent hardware, so that from it the details needed for automated processes area easily known - processes such as -
* dev-build/joetoobuild-tools' jb-mksys (automated interactive initial- or re-build of a matching system from a liveCD/liveUSB start point)
* dev-sbc/crossbuild-tools cb-mkimg (automated interactive crossbuild of an image file that can be deployed to a real physical system, or mounted on the build host to serve as a binary package server for systems of that architecture - e.g. a binhost for Raspberry Pi 5 bcm2712-rpi-5-b arm64/aarch64, hosted on your amd64 development workstation)
* dev-sbc/crossbuild-tools cb-mkupd (automated interactive crossbuild-update of an image file containing a complete system previously built with cb-mkimg or captured with dd from a working systems block device(s)).

This board and platform framework also facilitates the development and maintenance of policies implemented by joetoo ebuilds (determining what software components are required to support the current system running the ebuild to install joetoo packages).  User-control of this process is implemented in USE flags in several joetoo packages, principally joetoo-base/joetoo-platform-meta

One near-term architectural goal for joetoo is the centralization this knowledge described above, so individual packages do not each maintain independent lists or `case` statements for every supported board (as is currently the case in supporting ebuilds).  To that end a joetoo platform eclass is beginning development.

See the [joetoo Platform Architecture](https://github.com/JosephBrendler/myUtilities/blob/master/docs/platform-architecture.md).


## Major Components

### `dev-build`

Packages providing joetoo system-building automation infrastructure.

This includes the packaging used to install and execute the tools that construct Gentoo/joetoo systems for supported architectures and platforms.

[More about build infrastructure](docs/architecture/build-infrastructure.md)

### `dev-sbc`

Packages for automated interactive cross-building, QEMU support, SBC integration, status/control facilities, and related board-oriented infrastructure.

The category name reflects the historical origin of these packages; some components now participate in the architecture-independent joetoo platform model.

[More about cross-build architecture](docs/architecture/crossbuild.md)

### `dev-util`

General joetoo utilities installed on target systems, including joetoolkit, the script_header_joetoo family, and mkinitramfs (joetoo's automated custom initramfs builder).

[More about joetoo utilities](docs/architecture/utilities.md)

### `joetoo-base`

Packages defining or installing config files defining platform-specific and common joetoo system configuration policy, features, and functionality.

[More about the base system](docs/architecture/base-system.md)

### `sys-kernel`

Kernel-related packages supporting kernel construction (including crossbuilding), resulting published pre-built/platform-specific kernel images, installation, and update workflows.

[More about kernel architecture](docs/architecture/kernel-architecture.md)

## Relationship to the `joetoo` Repository

`myUtilities` contains **source and implementation**.

The [joetoo](https://github.com/JosephBrendler/joetoo) repository contains the corresponding **Gentoo ebuilds, metadata, profiles, package integration, and repository-level configuration** used to deploy that software through Portage.

The repositories should therefore be considered two parts of the same system rather than independent projects:

```text
                 joetoo platform architecture
                           |
              +------------+------------+
              |                         |
              v                         v
         myUtilities                  joetoo
       source / logic            ebuilds / packaging
              |                         |
              +------------+------------+
                           |
                           v
                  installed joetoo system
```

## Documentation

Architecture documentation (work in progress) begins with:

[**joetoo Platform Architecture**](docs/platform-architecture.md)

That document provides the high-level architectural map and links to detailed documents under `docs/architecture/`, and it is intended to distinguish the current architecture from historical implementation details and to provide a clear description of how joetoo components interact.

## Development Status

joetoo is an actively developed personal Linux infrastructure project originally begun in 2014. Interfaces, package organization, platform definitions, and build procedures may change as the common platform architecture is consolidated. Existing naming sometimes reflects the project's origins in SBC support even where the underlying mechanism now applies more generalized.

## Development and AI Assistance

joetoo's human developer(s) may use AI tools for research, discussion, debugging, design review, and suggestions. AI tools may be used in an advisory capacity only. Developers may not authorize any agentic AI system to modify the repository, execute its development workflow, or commit changes.

All changes to this repository are made, reviewed, tested as appropriate, documented in the VCS workflow, and committed by a human developer. The human developer(s) retain responsibility for the design, implementation, correctness, licensing, and provenance of committed content.

## License

See the licensing information associated with the individual source components in this repository.
