ARG BASE_TAG=latest
FROM ksmanis/portage:$BASE_TAG AS portage
FROM ksmanis/stage3:$BASE_TAG AS distcc-builder
COPY --from=portage /var/db/repos/gentoo/ /var/db/repos/gentoo/
RUN emerge -1q distcc
RUN rm -rf /var/cache/distfiles/* /var/db/repos/gentoo/

FROM scratch AS distcc-builder-squashed
COPY --from=distcc-builder / /
ARG BUILD_DATETIME
ARG VCS_REF
LABEL org.opencontainers.image.title="gentoo-distcc" \
      org.opencontainers.image.description="Gentoo Docker image with distcc that can be used to speed up compilation jobs" \
      org.opencontainers.image.authors="Konstantinos Smanis <konstantinos.smanis@gmail.com>" \
      org.opencontainers.image.source="https://github.com/KSmanis/docker-gentoo-distcc" \
      org.opencontainers.image.revision="$VCS_REF" \
      org.opencontainers.image.created="$BUILD_DATETIME"

FROM distcc-builder-squashed AS distcc-tcp
ARG TINI_VERSION=0.19.0
ARG TINI_GPGKEY=595E85A6B1B4779EA4DAAEC70B588DFF0527A9B7
ARG TINI_SHA256=93dcc18adc78c65a028a84799ecf8ad40c936fdfc5f2a57b1acda5a8117fa82c
RUN set -eux; \
    curl -fL "https://github.com/krallin/tini/releases/download/v${TINI_VERSION}/tini" -o /usr/local/bin/tini; \
    curl -fL "https://github.com/krallin/tini/releases/download/v${TINI_VERSION}/tini.asc" -o /usr/local/bin/tini.asc; \
    export GNUPGHOME="$(mktemp -d)"; \
    gpg --batch --keyserver ha.pool.sks-keyservers.net --recv-keys "${TINI_GPGKEY}"; \
    gpg --batch --verify /usr/local/bin/tini.asc /usr/local/bin/tini; \
    gpgconf --kill all; \
    rm -rf "${GNUPGHOME}" /usr/local/bin/tini.asc; \
    echo "${TINI_SHA256}  /usr/local/bin/tini" | sha256sum --check --strict; \
    chmod +x /usr/local/bin/tini; \
    tini --version
COPY docker-entrypoint-tcp.sh /usr/local/bin/docker-entrypoint.sh
# distccd exits with code 143 for SIGTERM; remap it to 0
ENTRYPOINT ["tini", "-e", "143", "--", "docker-entrypoint.sh"]
EXPOSE 3632

FROM distcc-builder-squashed AS distcc-ssh
ENV SSH_USERNAME=distcc-ssh
COPY docker-entrypoint-ssh.sh /usr/local/bin/docker-entrypoint.sh
ENTRYPOINT ["docker-entrypoint.sh"]
EXPOSE 22
