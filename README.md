# Gentoo Docker container with distcc
[![Docker Build Status](https://img.shields.io/docker/cloud/build/ksmanis/gentoo-distcc)](https://hub.docker.com/r/ksmanis/gentoo-distcc)

Minimal Gentoo Docker container with distcc that can be used to speed up compilation jobs.

## Features
 * Flexible deployment
   * Locally (in a private network)
   * Remotely (over the Internet)
 * Out-of-the-box support for the `amd64` Gentoo architecture

## Usage
distcc can run over TCP or SSH connections. TCP connections are fast but relatively insecure, whereas SSH connections are secure but slower. In a trusted environment, such as a LAN, you should use TCP connections for efficiency; otherwise use SSH connections.

### TCP
On the worker node(s), run the containerized distcc server (distccd):
```shell
docker run -d -p 3632:3632 --init --name gentoo-distcc-tcp --rm ksmanis/gentoo-distcc:tcp
```

distccd should now be accessible from all interfaces at port 3632 (`0.0.0.0:3632`):
```shell
$ docker ps
CONTAINER ID        IMAGE                       COMMAND                  CREATED             STATUS              PORTS                    NAMES
fd2207fca306        ksmanis/gentoo-distcc:tcp   "distccd --daemon --…"   4 seconds ago       Up 3 seconds        0.0.0.0:3632->3632/tcp   gentoo-distcc-tcp
```

Any extra arguments are passed on verbatim to distccd. For instance, you can turn on the built-in HTTP statistics server:
```shell
docker run -d -p 3632-3633:3632-3633 --init --name gentoo-distcc-tcp --rm ksmanis/gentoo-distcc:tcp --stats
```

The statistics server should now be accessible from all interfaces at port 3633 (`0.0.0.0:3633`):
```shell
$ docker ps
CONTAINER ID        IMAGE                       COMMAND                  CREATED             STATUS              PORTS                              NAMES
04f5cf5eaa4a        ksmanis/gentoo-distcc:tcp   "distccd --daemon --…"   2 seconds ago       Up 1 second         0.0.0.0:3632-3633->3632-3633/tcp   gentoo-distcc-tcp
```

For a full list of options, refer to [distccd(1)](https://linux.die.net/man/1/distccd).

*Note*: distccd is not designed to run as PID 1. As a result, it is highly recommended to use the [`--init`](https://docs.docker.com/engine/reference/run/#specify-an-init-process) docker run flag, as shown above, for distccd to behave correctly.

### SSH
On the worker node(s), run the containerized SSH server (sshd):
```shell
docker run -d -p 30022:22 -e AUTHORIZED_KEYS="..." --name gentoo-distcc-ssh --rm ksmanis/gentoo-distcc:ssh
```

sshd should now be accessible from all interfaces at port 30022 (`0.0.0.0:30022`):
```shell
$ docker ps
CONTAINER ID        IMAGE                       COMMAND                  CREATED             STATUS              PORTS                   NAMES
30cecb2ddae4        ksmanis/gentoo-distcc:ssh   "/entrypoint-distcc-…"   3 seconds ago       Up 1 second         0.0.0.0:30022->22/tcp   gentoo-distcc-ssh
```

Only the `distcc-ssh` user is accessible with the public key provided with the required `AUTHORIZED_KEYS` environment variable. The username is configurable through the optional `USER` environment variable:
```shell
docker run -d -p 30022:22 -e USER=bob -e AUTHORIZED_KEYS="..." --name gentoo-distcc-ssh --rm ksmanis/gentoo-distcc:ssh
```

*Tip*: Instead of including the public key verbatim in the above command, you may prefer to read it from a file on the Docker host:
```shell
docker run -d -p 30022:22 -e AUTHORIZED_KEYS="$(cat /path/to/key.pub)" --name gentoo-distcc-ssh --rm ksmanis/gentoo-distcc:ssh
```

## Testing
A manual way to test the containers is to compile a sample C file:
```c
#include <stdio.h>

int main() {
    printf("Hello, distcc!\n");
    return 0;
}
```

### TCP
```shell
DISTCC_HOSTS="127.0.0.1:3632" DISTCC_VERBOSE=1 distcc gcc -c main.c -o /dev/null
```

### SSH
```shell
DISTCC_HOSTS="@localhost-distcc" DISTCC_VERBOSE=1 distcc gcc -c main.c -o /dev/null
```

The `localhost-distcc` host should be properly set up in your `~/.ssh/config`:
```
Host localhost-distcc
    HostName 127.0.0.1
    Port 30022
    User distcc-ssh
    IdentityFile ~/.ssh/distcc
    StrictHostKeyChecking no
```

*Note*: `StrictHostKeyChecking no` is required in the above configuration because the host keys of the container are automatically regenerated upon execution, if missing. If you wish to remove this potential security issue, you should store the host keys in a volume and mount them upon execution so that they are not regenerated.

## Build
Should you wish to roll your own version, e.g., with an unstable toolchain, the [build](hooks/build) script can be a good starting point.
