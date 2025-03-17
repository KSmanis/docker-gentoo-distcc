# syntax=docker/dockerfile:1.14.0@sha256:4c68376a702446fc3c79af22de146a148bc3367e73c25a5803d453b6b3f722fb
ARG BASE=distcc

FROM ksmanis/stage3:20250317@sha256:7d5ae9ba500b482970424b8d9797a1b8a92f32f3643bcc547052a7fcf503f4e8 AS distcc
ARG CROSSDEV_TARGETS=
RUN --mount=type=bind,from=ksmanis/gentoo-distcc:tcp,source=/var/cache/binpkgs,target=/cache \
    --mount=type=bind,from=ksmanis/portage,source=/var/db/repos/gentoo,target=/var/db/repos/gentoo \
    set -eux; \
    cp -av /cache/. /var/cache/binpkgs; \
    getuto; \
    export EMERGE_DEFAULT_OPTS="--buildpkg --color=y --getbinpkg --quiet-build --tree --verbose"; \
    emerge --info; \
    emerge distcc; \
    distcc --version; \
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
    emerge --oneshot gentoolkit; \
    eclean packages; \
    CLEAN_DELAY=0 emerge --depclean gentoolkit; \
    find /var/cache/distfiles/ -mindepth 1 -delete -print; \
    rm -rf /etc/portage/gnupg/

FROM distcc AS distcc-ccache
RUN --mount=type=bind,from=ksmanis/gentoo-distcc:tcp-ccache,source=/var/cache/binpkgs,target=/cache \
    --mount=type=bind,from=ksmanis/portage,source=/var/db/repos/gentoo,target=/var/db/repos/gentoo \
    set -eux; \
    cp -av /cache/. /var/cache/binpkgs; \
    getuto; \
    export EMERGE_DEFAULT_OPTS="--buildpkg --color=y --getbinpkg --quiet-build --tree --verbose"; \
    emerge --info; \
    emerge ccache; \
    ccache --version; \
    emerge --oneshot gentoolkit; \
    eclean packages; \
    CLEAN_DELAY=0 emerge --depclean gentoolkit; \
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
FROM $BASE AS distcc-tcp
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
    wget -nv "https://github.com/krallin/tini/releases/download/v${TINI_VERSION}/tini-${TINI_ARCH}" -O /usr/local/bin/tini; \
    wget -nv "https://github.com/krallin/tini/releases/download/v${TINI_VERSION}/tini-${TINI_ARCH}.asc" -O /usr/local/bin/tini.asc; \
    wget -nv "https://github.com/krallin/tini/releases/download/v${TINI_VERSION}/tini-${TINI_ARCH}.sha256sum" -O /usr/local/bin/tini.sha256sum; \
    GNUPGHOME="$(mktemp -d)"; \
    export GNUPGHOME; \
    gpg --batch --keyserver keyserver.ubuntu.com --recv-keys "${TINI_GPGKEY}"; \
    gpg --batch --verify /usr/local/bin/tini.asc /usr/local/bin/tini; \
    gpgconf --kill all; \
    sed -i "s#tini-${TINI_ARCH}#/usr/local/bin/tini#" /usr/local/bin/tini.sha256sum; \
    sha256sum --check --strict /usr/local/bin/tini.sha256sum; \
    rm -rf "${GNUPGHOME}" /usr/local/bin/tini.asc /usr/local/bin/tini.sha256sum; \
    chmod +x /usr/local/bin/tini; \
    tini --version
COPY docker-entrypoint-tcp.sh /usr/local/bin/docker-entrypoint.sh
COPY healthcheck-tcp.sh /usr/local/bin/healthcheck.sh
# distccd exits with code 143 for SIGTERM; remap it to 0
ENTRYPOINT ["tini", "-e", "143", "--", "docker-entrypoint.sh"]
EXPOSE 3632
HEALTHCHECK CMD ["healthcheck.sh"]
USER distcc

# hadolint ignore=DL3006
FROM $BASE AS distcc-ssh
ENV SSH_USERNAME=distcc-ssh
COPY docker-entrypoint-ssh.sh /usr/local/bin/docker-entrypoint.sh
ENTRYPOINT ["docker-entrypoint.sh"]
EXPOSE 22
HEALTHCHECK CMD </dev/tcp/localhost/22 || exit 1

# hadolint ignore=DL3006
FROM $BASE AS distcc-tcp-test
ARG TEST_USERNAME=notroot
RUN useradd -G distcc ${TEST_USERNAME}
WORKDIR /home/${TEST_USERNAME}/
USER ${TEST_USERNAME}
COPY --chown=${TEST_USERNAME} tests/test.c ./
COPY --chown=${TEST_USERNAME} tests/test.sh ./
ENV DISTCC_BACKOFF_PERIOD=0
ENV DISTCC_FALLBACK=0
ENV DISTCC_VERBOSE=1
CMD ["./test.sh"]

FROM distcc-tcp-test AS distcc-ssh-test
ARG TEST_USERNAME=notroot
COPY --chown=${TEST_USERNAME} --chmod=600 tests/ssh_config .ssh/config
COPY --chown=${TEST_USERNAME} --chmod=600 tests/ssh_ed25519_key .ssh/id_ed25519
