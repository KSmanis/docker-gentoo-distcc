#!/bin/sh
set -eu

# Execute sshd in any of the following cases:
# * if no arguments were passed to the Docker command line
# * if hyphenated flag arguments (e.g., '-f', '-foo', or '--foo') were
#   passed to the Docker command line
if [ "$#" -eq 0 ] || [ "${1#-}" != "$1" ]; then
    # Create user and set up SSH access
    useradd "${SSH_USERNAME}"
    echo "${AUTHORIZED_KEYS}" > "/home/${SSH_USERNAME}/.ssh/authorized_keys"
    chown "${SSH_USERNAME}:${SSH_USERNAME}" "/home/${SSH_USERNAME}/.ssh/authorized_keys"
    chmod 600 "/home/${SSH_USERNAME}/.ssh/authorized_keys"
    # Create missing SSH host keys
    ssh-keygen -A
    # Execute sshd
    exec /usr/sbin/sshd -D -e "$@"
fi

exec "$@"
