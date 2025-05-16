# Gentoo Docker image with distcc

[![Docker Pulls](https://img.shields.io/docker/pulls/ksmanis/gentoo-distcc?label=pulls&logo=docker)](https://hub.docker.com/r/ksmanis/gentoo-distcc)
[![build](https://github.com/KSmanis/docker-gentoo-distcc/actions/workflows/build.yml/badge.svg)](https://github.com/KSmanis/docker-gentoo-distcc/actions/workflows/build.yml)
[![lint](https://github.com/KSmanis/docker-gentoo-distcc/actions/workflows/lint.yml/badge.svg)](https://github.com/KSmanis/docker-gentoo-distcc/actions/workflows/lint.yml)
[![pre-commit enabled](https://img.shields.io/badge/pre--commit-enabled-brightgreen?logo=pre-commit&logoColor=white)](https://github.com/pre-commit/pre-commit)
[![Renovate enabled](https://img.shields.io/badge/renovate-enabled-brightgreen.svg?logo=renovatebot&logoColor=white)](https://renovatebot.com/)
[![Conventional Commits](https://img.shields.io/badge/Conventional%20Commits-1.0.0-yellow.svg)](https://conventionalcommits.org)

Decrease Gentoo compilation times by leveraging spare resources, such as an
Ubuntu or Windows box idling around. Docker is the only prerequisite.

> [!IMPORTANT]
>
> The SSH image variants have been deprecated as of 2025-05-16 in order to ease
> maintenance and reduce resource usage. No SSH images will be built moving
> forward. As an alternative, consider using the TCP image variants either with
> a VPN (recommended) or a reverse SSH tunnel.

## Features

- Out-of-the-box support for the following Gentoo architectures:
  - `amd64`
  - `arm`
  - `arm64`
  - `ppc64`
  - `x86`
- Server-side caching using [ccache](#ccache)
- Cross-compilation support using [crossdev](#crossdev)

> [!NOTE]
>
> Only the stable toolchain of these architectures is supported.

## Usage

On the worker node(s), run the containerized distcc server (distccd):

```shell
docker run -d -p 3632:3632 --name gentoo-distcc-tcp --rm ksmanis/gentoo-distcc:tcp
```

distccd should now be accessible from all interfaces at port 3632
(`0.0.0.0:3632`):

```shell
$ docker ps
CONTAINER ID        IMAGE                       COMMAND                  CREATED             STATUS              PORTS                    NAMES
405bb6e87ce8        ksmanis/gentoo-distcc:tcp   "tini -e 143 -- dock…"   2 seconds ago       Up 2 seconds        0.0.0.0:3632->3632/tcp   gentoo-distcc-tcp
```

Command-line arguments are passed on verbatim to distccd. For instance, you can
turn on the built-in HTTP statistics server:

```shell
docker run -d -p 3632-3633:3632-3633 --name gentoo-distcc-tcp --rm ksmanis/gentoo-distcc:tcp --stats
```

The statistics server should now be accessible from all interfaces at port 3633
(`0.0.0.0:3633`):

```shell
$ docker ps
CONTAINER ID        IMAGE                       COMMAND                  CREATED             STATUS              PORTS                              NAMES
4e553e359782        ksmanis/gentoo-distcc:tcp   "tini -e 143 -- dock…"   3 seconds ago       Up 2 seconds        0.0.0.0:3632-3633->3632-3633/tcp   gentoo-distcc-tcp
```

For a full list of options refer to
[distccd(1)](https://linux.die.net/man/1/distccd).

### Ccache

If you share a worker instance between multiple clients, you might be interested
in enabling server-side caching with `ccache` to avoid redundant recompilations.
To do so, pull the `tcp-ccache` tag:

```shell
docker run -d -p 3632:3632 --name gentoo-distcc-tcp-ccache --rm ksmanis/gentoo-distcc:tcp-ccache
```

The directory `/var/cache/ccache` automatically persists in an anonymous Docker
volume, but a named Docker volume or a bind mount may also be used for stronger
persistence guarantees.

Ccache statistics can be queried as follows:

```shell
docker exec gentoo-distcc-tcp-ccache ccache -sv
```

## Crossdev

All `amd64` image variants support cross-compilation for the `arm64`
architecture (specifically the `aarch64-unknown-linux-gnu` toolchain) and vice
versa: all `arm64` image variants support cross-compilation for the `amd64`
architecture (specifically the `x86_64-pc-linux-gnu` toolchain). In other words,
an `amd64` desktop can be used to cross-compile for an `arm64` Raspberry Pi and
vice versa.

Cross-compilation support is enabled out of the box without any user
configuration. More architecture combinations can be added upon request.

## Testing

A manual way to test the containers is to compile a sample C file:

```c
#include <stdio.h>

int main() {
    printf("Hello, distcc!\n");
    return 0;
}
```

```shell
DISTCC_HOSTS="127.0.0.1:3632" DISTCC_VERBOSE=1 distcc gcc -c main.c -o /dev/null
```
