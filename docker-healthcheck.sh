#!/bin/sh
set -e

if [ -n "${CCACHE_DIR+x}" ]; then
    # Do not trigger ccache
    lsdistcc localhost
else
    lsdistcc -pgcc localhost
fi
