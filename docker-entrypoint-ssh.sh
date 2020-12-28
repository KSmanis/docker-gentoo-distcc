#!/bin/sh

# Create user and set up SSH access
useradd "${SSH_USERNAME}"
echo "${AUTHORIZED_KEYS}" > "/home/${SSH_USERNAME}/.ssh/authorized_keys"
chown "${SSH_USERNAME}:${SSH_USERNAME}" "/home/${SSH_USERNAME}/.ssh/authorized_keys"
chmod 600 "/home/${SSH_USERNAME}/.ssh/authorized_keys"

# Create missing SSH host keys and execute sshd
ssh-keygen -A
exec /usr/sbin/sshd -D -e "$@"
