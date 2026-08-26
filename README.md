# myUtilities

`myUtilities` is the source-code repository for **joetoo**, a collection of tools, system-building infrastructure, configuration utilities, and platform-support software used to build and maintain Gentoo Linux systems across multiple hardware architectures.

The corresponding Gentoo ebuild repository is [joetoo](https://github.com/JosephBrendler/joetoo).

## Purpose

The repository contains the upstream source for utilities that automate installation, configuration, cross-building, kernel management, system maintenance, and other tasks used throughout the joetoo environment.

Although much of the infrastructure originated in support of ARM single-board computers, joetoo is evolving into a common platform-management architecture supporting SBC and conventional systems across multiple architectures, including ARM, ARM64, and amd64/x86_64.

The source repository and ebuild repository intentionally have related directory structures:

```text
myUtilities                         joetoo
(source)                            (Gentoo packaging)

dev-build/                          dev-build/
dev-sbc/                            dev-sbc/
dev-util/                           dev-util/
joetoo-base/                        joetoo-base/
sys-kernel/                         sys-kernel/
   ...                                 ...
```

A package in the `joetoo` repository may therefore install, configure, or otherwise consume software maintained here.

## Platform Architecture

A joetoo installation is associated with a hardware **board** identity.

The term originated with joetoo's single-board-computer support, where the board is naturally a physical SBC. For conventional x86 systems, the same abstraction identifies the motherboard/CPU/chipset platform on which the system is built.

The board identity is used to resolve the properties needed to build and configure the system, including such things as:

* CPU architecture
* compiler target
* QEMU architecture
* Gentoo stage3 selection
* Gentoo profile
* LLVM target
* kernel/build strategy
* other board- or architecture-specific properties

In this documentation, **platform** refers more broadly to this resolved operating environment, while **board** remains the hardware identity and lookup key used by the existing joetoo implementation.

The intent is that platform knowledge be defined centrally and consumed by joetoo tools rather than reproduced independently throughout individual scripts and packages.

See [Platform Architecture](docs/platform-architecture.md).

## Major Components

### `dev-build`

System-building and installation infrastructure used to construct joetoo Gentoo systems.

This includes tooling for native system builds and the common build environment used by the broader joetoo platform infrastructure.

[More about build infrastructure](docs/architecture/build-infrastructure.md)

### `dev-sbc`

Cross-build and hardware-support utilities originating in joetoo's SBC support.

This includes cross-build tooling, QEMU-related support, board-specific utilities, and other facilities needed to construct and manage systems whose target architecture may differ from the build host.

Although the category retains its historical `dev-sbc` name, portions of this infrastructure participate in the common joetoo platform architecture.

[More about cross-build architecture](docs/architecture/crossbuild.md)

### `dev-util`

General joetoo utilities, including software intended for use on installed joetoo systems.

[More about joetoo utilities](docs/architecture/utilities.md)

### `joetoo-base`

Source components associated with the base joetoo environment and common system configuration.

[More about the base system](docs/architecture/base-system.md)

### `sys-kernel`

Kernel-related source and tooling used to build, package, install, and update kernels for supported joetoo platforms.

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

The architecture documentation begins with:

[**joetoo Platform Architecture**](docs/platform-architecture.md)

That document provides the high-level architectural map and links to detailed documents under `docs/architecture/`.

The documentation is intended to distinguish the current architecture from historical implementation details and to provide a canonical description of how joetoo components interact.

## Development Status

joetoo is an actively developed personal Linux infrastructure project originally begun in 2014. Interfaces, package organization, platform definitions, and build procedures may change as the common platform architecture is consolidated. Existing naming sometimes reflects the project's origins in SBC support even where the underlying mechanism now applies more generally.

## License

See the licensing information associated with the individual source components in this repository.
