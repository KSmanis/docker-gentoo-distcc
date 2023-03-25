#!/bin/sh
set -eux

export DOCKER_CLI_EXPERIMENTAL=enabled

set --
for arch in "386" "amd64" "armv6" "armv7" "arm64" "ppc64le"; do
    image="${REPO}:${arch}-${TAG}"
    if docker manifest inspect "${image}" 1>/dev/null 2>&1; then
        set -- "$@" "${image}"
    fi
done

manifest="${REPO}:${TAG}"
docker manifest create "${manifest}" "$@"
docker manifest push "${manifest}"
