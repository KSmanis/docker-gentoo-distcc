#!/bin/sh
set -eu

# Execute sshd with some default arguments in any of the following cases:
# * if no arguments were passed to the Docker command line
# * if hyphenated flag arguments (e.g., '-f', '-foo', or '--foo') were
#   passed to the Docker command line
if [ "$#" -eq 0 ] || [ "${1#-}" != "$1" ]; then
    set -- sshd -D -e "$@"
fi

if [ "$1" = "sshd" ]; then
    # Create user and set up SSH access
    id "${SSH_USERNAME}" >/dev/null 2>&1 || useradd -G distcc "${SSH_USERNAME}"
    mkdir -p "/home/${SSH_USERNAME}/.ssh"
    chown "${SSH_USERNAME}:${SSH_USERNAME}" "/home/${SSH_USERNAME}/.ssh"
    chmod 700 "/home/${SSH_USERNAME}/.ssh"
    echo "${AUTHORIZED_KEYS}" > "/home/${SSH_USERNAME}/.ssh/authorized_keys"
    chown "${SSH_USERNAME}:${SSH_USERNAME}" "/home/${SSH_USERNAME}/.ssh/authorized_keys"
    chmod 600 "/home/${SSH_USERNAME}/.ssh/authorized_keys"
    # Create missing SSH host keys
    ssh-keygen -A
    # Configure sshd
    if [ -n "${SSHD_LOG_LEVEL+x}" ]; then
      sed -i "/LogLevel/c\LogLevel ${SSHD_LOG_LEVEL}" /etc/ssh/sshd_config
    fi
    # Execute sshd using absolute path
    shift
    exec /usr/sbin/sshd "$@"
fi

# Execute whatever was passed to the Docker command line
exec "$@"
