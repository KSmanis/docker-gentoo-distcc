# syntax=docker/dockerfile:1.26.0@sha256:ecfaec9ed6d810b56388c508f4121597bfbba70d41a6dfeee4d8cad5f295fc32
ARG BASE=build-base
ARG BINREPO_BRANCH=
ARG BINREPO_PUBLISH=
ARG BINREPO_REPOSITORY=

FROM ghcr.io/ksmanis/stage3:20260817@sha256:99b37248a66bc90393f3ead3e8f8269dedc633a65e1d3928f97767b742e6ff46 AS build-base
ARG BINREPO_BRANCH
ARG BINREPO_PUBLISH
ARG BINREPO_REPOSITORY
ARG CLANG=
ARG CROSSDEV_TARGETS=
ARG TARGETPLATFORM
RUN --mount=type=bind,from=ghcr.io/ksmanis/portage,source=/var/db/repos/gentoo,target=/var/db/repos/gentoo \
    --mount=type=cache,id=base,target=/var/cache/binpkgs \
    --mount=type=secret,id=gh_token \
    set -eux; \
    getuto; \
    export EMERGE_DEFAULT_OPTS="--buildpkg --color=y --getbinpkg --jobs --quiet-build --tree --verbose"; \
    emerge --info; \
    emerge distcc; \
    distcc --version; \
    if [ -n "${CLANG}" ]; then \
        case "${TARGETPLATFORM}" in \
            "linux/arm/v6" | "linux/arm/v7") export LDFLAGS=-latomic ;; \
        esac; \
        emerge llvm-core/clang; \
        . /etc/profile.env; \
        clang --version; \
    fi; \
    if [ -n "${CROSSDEV_TARGETS}" ]; then \
        emerge crossdev; \
        crossdev --version; \
        mkdir -p /var/db/repos/crossdev/metadata; \
        echo 'masters = gentoo' > /var/db/repos/crossdev/metadata/layout.conf; \
        mkdir -p /var/db/repos/crossdev/profiles; \
        echo 'crossdev' > /var/db/repos/crossdev/profiles/repo_name; \
        chown -R portage:portage /var/db/repos/crossdev; \
        mkdir -p /etc/portage/repos.conf; \
        printf '[crossdev]\nlocation = /var/db/repos/crossdev\npriority = 10\nmasters = gentoo\nauto-sync = no\n' > /etc/portage/repos.conf/crossdev.conf; \
        for target in ${CROSSDEV_TARGETS}; do \
            crossdev --portage '--buildpkg --usepkg' --stable --target "${target}"; \
        done; \
    fi; \
    if [ -n "${BINREPO_PUBLISH}" ]; then \
        mkdir -p /var/db/repos/rookery; \
        wget -nv 'https://github.com/KSmanis/rookery/archive/HEAD.tar.gz' -O /var/db/repos/rookery.tar.gz; \
        tar -xzf /var/db/repos/rookery.tar.gz --strip-components=1 -C /var/db/repos/rookery; \
        rm /var/db/repos/rookery.tar.gz; \
        mkdir -p /etc/portage/repos.conf; \
        printf '[rookery]\nauto-sync = no\nlocation = /var/db/repos/rookery\n' > /etc/portage/repos.conf/rookery.conf; \
        ACCEPT_KEYWORDS='**' emerge --oneshot app-portage/portage-github-binrepo; \
        printf 'branch = %s\nrepository = %s\ntoken-file = /run/secrets/gh_token\n' "${BINREPO_BRANCH}" "${BINREPO_REPOSITORY}" > /etc/portage/github-binrepo.conf; \
        portage-github-binrepo check; \
    fi; \
    emerge --oneshot gentoolkit; \
    eclean packages; \
    if [ -n "${BINREPO_PUBLISH}" ]; then portage-github-binrepo push; fi; \
    CLEAN_DELAY=0 emerge --depclean gentoolkit; \
    if [ -n "${BINREPO_PUBLISH}" ]; then \
        CLEAN_DELAY=0 emerge --depclean app-portage/portage-github-binrepo; \
        rm -rf /etc/portage/github-binrepo.conf /etc/portage/repos.conf/rookery.conf /var/db/repos/rookery; \
    fi; \
    find /var/cache/distfiles/ -mindepth 1 -delete -print; \
    rm -rf /etc/portage/gnupg/

FROM build-base AS build-ccache
ARG BINREPO_BRANCH
ARG BINREPO_PUBLISH
ARG BINREPO_REPOSITORY
RUN --mount=type=bind,from=ghcr.io/ksmanis/portage,source=/var/db/repos/gentoo,target=/var/db/repos/gentoo \
    --mount=type=cache,id=ccache,target=/var/cache/binpkgs \
    --mount=type=secret,id=gh_token \
    set -eux; \
    getuto; \
    export EMERGE_DEFAULT_OPTS="--buildpkg --color=y --getbinpkg --jobs --quiet-build --tree --verbose"; \
    if [ -n "${BINREPO_PUBLISH}" ]; then \
        mkdir -p /var/db/repos/rookery; \
        wget -nv 'https://github.com/KSmanis/rookery/archive/HEAD.tar.gz' -O /var/db/repos/rookery.tar.gz; \
        tar -xzf /var/db/repos/rookery.tar.gz --strip-components=1 -C /var/db/repos/rookery; \
        rm /var/db/repos/rookery.tar.gz; \
        mkdir -p /etc/portage/repos.conf; \
        printf '[rookery]\nauto-sync = no\nlocation = /var/db/repos/rookery\n' > /etc/portage/repos.conf/rookery.conf; \
        ACCEPT_KEYWORDS='**' emerge --oneshot app-portage/portage-github-binrepo; \
        printf 'branch = %s\nrepository = %s\ntoken-file = /run/secrets/gh_token\n' "${BINREPO_BRANCH}" "${BINREPO_REPOSITORY}" > /etc/portage/github-binrepo.conf; \
        portage-github-binrepo check; \
        portage-github-binrepo pull; \
    fi; \
    emerge --info; \
    mkdir -p /etc/portage/package.use; \
    echo 'dev-util/ccache http redis' > /etc/portage/package.use/ccache; \
    emerge ccache; \
    ccache --version; \
    emerge --oneshot gentoolkit; \
    eclean packages; \
    if [ -n "${BINREPO_PUBLISH}" ]; then portage-github-binrepo push; fi; \
    CLEAN_DELAY=0 emerge --depclean gentoolkit; \
    if [ -n "${BINREPO_PUBLISH}" ]; then \
        CLEAN_DELAY=0 emerge --depclean app-portage/portage-github-binrepo; \
        rm -rf /etc/portage/github-binrepo.conf /etc/portage/repos.conf/rookery.conf /var/db/repos/rookery; \
    fi; \
    find /var/cache/distfiles/ -mindepth 1 -delete -print; \
    rm -rf /etc/portage/gnupg/
ARG CCACHE_DIR=/var/cache/ccache
ENV CCACHE_DIR="$CCACHE_DIR"
ENV PATH="/usr/lib/ccache/bin${PATH:+:$PATH}"
RUN set -eux; \
    printf 'CCACHE_DIR="%s"\nPATH="/usr/lib/ccache/bin"\n' "$CCACHE_DIR" > /etc/env.d/02distcc-ccache; \
    env-update; \
    mkdir -p "${CCACHE_DIR}"; \
    chmod 0775 "${CCACHE_DIR}"; \
    chown distcc:distcc "${CCACHE_DIR}"
VOLUME ["$CCACHE_DIR"]

# hadolint ignore=DL3006
FROM $BASE AS distcc
ARG TARGETPLATFORM
# renovate: datasource=github-tags depName=krallin/tini
ARG TINI_VERSION=0.19.0
ARG TINI_GPGKEY=595E85A6B1B4779EA4DAAEC70B588DFF0527A9B7
RUN set -eux; \
    case "$TARGETPLATFORM" in \
        "linux/386") TINI_ARCH="i386" ;; \
        "linux/amd64") TINI_ARCH="amd64" ;; \
        "linux/arm/v6" | "linux/arm/v7") TINI_ARCH="armhf" ;; \
        "linux/arm64") TINI_ARCH="arm64" ;; \
        "linux/ppc64le") TINI_ARCH="ppc64le" ;; \
        *) echo "Error: Unsupported TARGETPLATFORM '$TARGETPLATFORM'" >&2; exit 1 ;; \
    esac; \
    wget -nv "https://github.com/krallin/tini/releases/download/v${TINI_VERSION}/tini-static-${TINI_ARCH}" -O /usr/local/bin/tini; \
    wget -nv "https://github.com/krallin/tini/releases/download/v${TINI_VERSION}/tini-static-${TINI_ARCH}.asc" -O /usr/local/bin/tini.asc; \
    wget -nv "https://github.com/krallin/tini/releases/download/v${TINI_VERSION}/tini-static-${TINI_ARCH}.sha256sum" -O /usr/local/bin/tini.sha256sum; \
    GNUPGHOME="$(mktemp -d)"; \
    export GNUPGHOME; \
    gpg --batch --keyserver keyserver.ubuntu.com --recv-keys "${TINI_GPGKEY}"; \
    gpg --batch --verify /usr/local/bin/tini.asc /usr/local/bin/tini; \
    gpgconf --kill all; \
    sed -i "s#tini-static-${TINI_ARCH}#/usr/local/bin/tini#" /usr/local/bin/tini.sha256sum; \
    sha256sum --check --strict /usr/local/bin/tini.sha256sum; \
    rm -rf "${GNUPGHOME}" /usr/local/bin/tini.asc /usr/local/bin/tini.sha256sum; \
    chmod +x /usr/local/bin/tini; \
    tini --version
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
COPY docker-healthcheck.sh /usr/local/bin/docker-healthcheck.sh
# distccd exits with code 143 for SIGTERM; remap it to 0
ENTRYPOINT ["tini", "-e", "143", "--", "docker-entrypoint.sh"]
EXPOSE 3632
HEALTHCHECK CMD ["docker-healthcheck.sh"]
# hadolint ignore=DL3066
USER distcc

# hadolint ignore=DL3006
FROM $BASE AS test
# hadolint ignore=DL3064
ARG TEST_USERNAME=notroot
RUN useradd -G distcc ${TEST_USERNAME}
WORKDIR /home/${TEST_USERNAME}/
# hadolint ignore=DL3066
USER ${TEST_USERNAME}
COPY --chown=${TEST_USERNAME} tests/test.c ./
COPY --chown=${TEST_USERNAME} tests/test.sh ./
ENV DISTCC_BACKOFF_PERIOD=0
ENV DISTCC_FALLBACK=0
ENV DISTCC_VERBOSE=1
CMD ["./test.sh"]
