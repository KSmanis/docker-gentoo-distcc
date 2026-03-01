#!/bin/sh
set -eux

# shellcheck disable=SC1091
. /etc/profile.env

# Validate ccache is empty
if [ -n "${CCACHE_DIR+x}" ]; then
    [ "$(ccache --print-stats | grep '^files_in_cache' | cut -f2)" -eq 0 ]
fi

# Compile
env -u CCACHE_DIR gcc -c test.c -o test-gcc.o
env -u CCACHE_DIR distcc gcc -c test.c -o test-distcc.o
if command -v clang >/dev/null 2>&1; then
    env -u CCACHE_DIR clang -c test.c -o test-clang.o
    env -u CCACHE_DIR distcc clang -c test.c -o test-distcc-clang.o
fi

# Link
gcc test-gcc.o -o test-gcc
gcc test-distcc.o -o test-distcc
if command -v clang >/dev/null 2>&1; then
    clang test-clang.o -o test-clang
    clang test-distcc-clang.o -o test-distcc-clang
fi

# Inspect
file test-gcc test-distcc
readelf -h test-gcc test-distcc
if command -v clang >/dev/null 2>&1; then
    file test-clang test-distcc-clang
    readelf -h test-clang test-distcc-clang
fi

# Execute
[ "$(./test-gcc)" = "$(./test-distcc)" ]
if command -v clang >/dev/null 2>&1; then
    [ "$(./test-clang)" = "$(./test-distcc-clang)" ]
    [ "$(./test-gcc)" = "$(./test-clang)" ]
fi

# Validate ccache was triggered
if [ -n "${CCACHE_DIR+x}" ]; then
    [ "$(ccache --print-stats | grep '^files_in_cache' | cut -f2)" -gt 0 ]
fi
