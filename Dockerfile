FROM gentoo/stage3-amd64 AS distcc-builder
COPY --from=gentoo/portage /var/db/repos/gentoo /var/db/repos/gentoo
RUN emerge -1q distcc
RUN rm -rf /var/cache/distfiles/* /var/db/repos/gentoo/

FROM scratch AS distcc-tcp
COPY --from=distcc-builder / /
ENTRYPOINT ["distccd", "--daemon", "--no-detach", "--log-level", "notice", "--log-stderr", "--allow-private"]
EXPOSE 3632

FROM scratch AS distcc-ssh
COPY --from=distcc-builder / /
ARG user=distcc-ssh
RUN useradd ${user} && \
    touch /home/${user}/.ssh/authorized_keys && \
    chown ${user}:${user} /home/${user}/.ssh/authorized_keys && \
    chmod 600 /home/${user}/.ssh/authorized_keys && \
    ssh-keygen -A
ENTRYPOINT ["/usr/sbin/sshd", "-D", "-e"]
EXPOSE 22
