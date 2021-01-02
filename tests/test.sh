#!/bin/sh
set -eux

# Based on https://gist.github.com/sj26/88e1c6584397bb7c13bd11108a579746
retry() {
    max_retries=$1
    shift

    retries=0
    delay=1
    until "$@"; do
        exit=$?
        retries=$((retries + 1))
        if [ "$retries" -lt "$max_retries" ]; then
            echo "[$retries/$max_retries] \`$*\` failed with exit code $exit; sleeping for ${delay}s..."
            sleep $delay
        else
            echo "[$retries/$max_retries] \`$*\` failed with exit code $exit; aborting..."
            return $exit
        fi
        delay=$((delay * 2))
    done
    return 0
}

# Compile
gcc -c test.c -o test-gcc.o
retry 5 distcc gcc -c test.c -o test-distcc.o

# Link
gcc test-gcc.o -o test-gcc
gcc test-distcc.o -o test-distcc

# Inspect
file test-gcc test-distcc
readelf -h test-gcc test-distcc

# Execute
[ "$(./test-gcc)" = "$(./test-distcc)" ]
