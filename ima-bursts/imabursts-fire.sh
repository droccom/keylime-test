#!/bin/bash

if [ $# -lt 3 ]; then
    echo "usage: $0 PREFIX BURST_LEN BURST_CNT"
    exit
fi

PREFIX=$1; shift
BURST_LEN=$1; shift
BURST_CNT=$1; shift

fcnt=1
for bi in $(seq 1 $BURST_LEN); do
    for bj in $(seq 1 $BURST_CNT); do
        $PREFIX$fcnt > /dev/null
        fcnt=$((fcnt+1))
    done
done