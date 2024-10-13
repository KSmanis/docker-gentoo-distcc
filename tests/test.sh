#!/bin/sh
set -eux

# Validate ccache is empty
if [ -n "${CCACHE_DIR+x}" ]; then
    [ "$(ccache --print-stats | grep '^files_in_cache' | cut -f2)" -eq 0 ]
fi

# Compile
env -u CCACHE_DIR gcc -c test.c -o test-gcc.o
env -u CCACHE_DIR distcc gcc -c test.c -o test-distcc.o

# Link
gcc test-gcc.o -o test-gcc
gcc test-distcc.o -o test-distcc

# Inspect
file test-gcc test-distcc
readelf -h test-gcc test-distcc

# Execute
[ "$(./test-gcc)" = "$(./test-distcc)" ]

# Validate ccache was triggered
if [ -n "${CCACHE_DIR+x}" ]; then
    [ "$(ccache --print-stats | grep '^files_in_cache' | cut -f2)" -gt 0 ]
fi
