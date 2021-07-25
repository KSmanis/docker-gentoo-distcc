#!/bin/sh
set -eux

# Compile
gcc -c test.c -o test-gcc.o
distcc gcc -c test.c -o test-distcc.o

# Link
gcc test-gcc.o -o test-gcc
gcc test-distcc.o -o test-distcc

# Inspect
file test-gcc test-distcc
readelf -h test-gcc test-distcc

# Execute
[ "$(./test-gcc)" = "$(./test-distcc)" ]
