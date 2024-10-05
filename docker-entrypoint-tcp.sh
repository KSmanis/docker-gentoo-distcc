#!/bin/sh
set -e

# Execute distccd with some default arguments in any of the following cases:
# * if no arguments were passed to the Docker command line
# * if hyphenated flag arguments (e.g., '-f', '-foo', or '--foo') were
#   passed to the Docker command line
if [ "$#" -eq 0 ] || [ "${1#-}" != "$1" ]; then
    if [ "${DISTCC_CCACHE_ENABLE}" = 1 ]; then
        export PATH="/usr/lib/ccache/bin:$PATH"
    fi
    exec distccd --daemon --no-detach --log-level notice --log-stderr --allow-private "$@"
fi

# Execute whatever was passed to the Docker command line
exec "$@"
