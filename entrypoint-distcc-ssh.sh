#!/bin/sh

# Create user and set up SSH access
useradd "${USER}"
echo "${AUTHORIZED_KEYS}" > "/home/${USER}/.ssh/authorized_keys"
chown "${USER}:${USER}" "/home/${USER}/.ssh/authorized_keys"
chmod 600 "/home/${USER}/.ssh/authorized_keys"

# Create missing SSH host keys and execute sshd
ssh-keygen -A
exec /usr/sbin/sshd -D -e "$@"
