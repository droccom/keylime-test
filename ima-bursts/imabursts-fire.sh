#!/bin/bash

if [ $# -lt 4 ]; then
    echo "usage: $0 PREFIX BURST_LEN BURST_CNT BURST_WAIT_LIMIT"
    exit
fi

PREFIX=$1; shift
BURST_LEN=$1; shift
BURST_CNT=$1; shift
BURST_WAIT_LIMIT=$1; shift

echo "[$0] parameters: BURST_LEN=$BURST_LEN \
BURST_CNT=$BURST_CNT \
BURST_WAIT_LIMIT=$BURST_WAIT_LIMIT"

fcnt=1
for bi in $(seq 1 $BURST_CNT); do
    echo "[$0] *** BURST #$bi"
    burst_wait=$(($RANDOM % $BURST_WAIT_LIMIT))
    echo "[$0] > sleeping $burst_wait secs"
    sleep $burst_wait
    for bj in $(seq 1 $BURST_LEN); do
        $PREFIX$fcnt > /dev/null
        fcnt=$((fcnt+1))
    done
done
