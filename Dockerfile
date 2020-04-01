FROM gentoo/stage3-amd64 AS distcc-builder
COPY --from=gentoo/portage /var/db/repos/gentoo /var/db/repos/gentoo
RUN emerge -1q distcc
RUN rm -rf /var/cache/distfiles/* /var/db/repos/gentoo/

FROM scratch AS distcc-builder-squashed
COPY --from=distcc-builder / /

FROM distcc-builder-squashed AS distcc-tcp
ENTRYPOINT ["distccd", "--daemon", "--no-detach", "--log-level", "notice", "--log-stderr", "--allow-private"]
EXPOSE 3632

FROM distcc-builder-squashed AS distcc-ssh
ENV USER=distcc-ssh
COPY entrypoint-distcc-ssh.sh /
ENTRYPOINT ["/entrypoint-distcc-ssh.sh"]
EXPOSE 22
