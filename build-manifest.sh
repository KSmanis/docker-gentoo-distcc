#!/bin/sh
set -eux

export DOCKER_CLI_EXPERIMENTAL=enabled

manifest="${REPO}:${TAG}"
for arch in "386" "amd64" "armv6" "armv7" "arm64" "ppc64le"; do
    image="${REPO}:${arch}-${TAG}"
    docker manifest create --amend "${manifest}" "${image}" || true
done
docker manifest push "${manifest}"
