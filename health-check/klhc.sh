#!/bin/bash

VERBOSE=1

set -e

EGREP_UUID="egrep -o [A-Z0-9]+-[A-Z0-9]+-[A-Z0-9]+-[A-Z0-9]+-[A-Z0-9#]+"
EGREP_REGISTERED="egrep 'adding agent'"
EGREP_IMA="egrep 'Checking IMA'"
EGREP_FAILED="egrep 'failed'"

if [ $# -lt 2 ]; then
    echo "usage: $0 BAREMETAL|DOCKER|EXTLOGS LOGTAIL"
    exit
fi

MODE=$1; shift
LOGTAIL=$1; shift

if [ $MODE == "DOCKER" ]; then
    CMD_PREFIX="docker logs keylime_verifier | $EGREP_REGISTERED"
elif [ $MODE == "BAREMETAL" ]; then
    CMD_PREFIX="journalctl --no-pager -u keylime_verifier.service | $EGREP_REGISTERED"
elif [ $MODE == "EXTLOGS" ]; then
    if [[ -z ${EXTLOGS_PREFIX+x} ]]; then
        echo "EXTLOGS_PREFIX must be defined for $MODE mode"
        exit
    fi
    CMD_PREFIX="sudo $EGREP_REGISTERED ${EXTLOGS_PREFIX}/keylime_verifier-*.log"
fi
CMD_ADDED_AGENTS="$CMD_PREFIX | $EGREP_UUID"

echo "registered agents:"
cmd="$CMD_ADDED_AGENTS | sort | uniq | wc -l"
if [ "$VERBOSE" == 1 ]; then echo $cmd; fi
eval $cmd

echo
echo "healthy agents over latest $LOGTAIL per-verifier IMA logs:"
if [ $MODE == "DOCKER" ]; then
    CMD_PREFIX="docker logs keylime_verifier | $EGREP_IMA | tail -n $LOGTAIL"
elif [ $MODE == "BAREMETAL" ]; then
    CMD_PREFIX="journalctl --no-pager -u keylime_verifier.service | $EGREP_IMA | tail -n $LOGTAIL"
elif [ $MODE == "EXTLOGS" ]; then
    CMD_PREFIX="sudo tail -n $LOGTAIL ${EXTLOGS_PREFIX}/keylime_verifier-*.log | $EGREP_IMA"
fi
cmd="$CMD_PREFIX | $EGREP_UUID | sort | uniq | wc -l"
if [[ "$VERBOSE" == 1 ]]; then echo $cmd; fi
eval $cmd

echo
echo "failed agents:"
if [ $MODE == "DOCKER" ]; then
    for a in $(docker logs keylime_verifier | $EGREP_FAILED | $EGREP_UUID); do
        echo "failing agent: $a"
        docker logs keylime_verifier | grep $a | tail -n 2
    done
elif [ $MODE == "BAREMETAL" ]; then
    for a in $(journalctl --no-pager -u keylime_verifier.service | $EGREP_FAILED | $EGREP_UUID); do
        echo "failing agent: $a"
    	journalctl --no-pager -u keylime_verifier.service | grep $a | tail -n 2
    done
elif [ $MODE == "EXTLOGS" ]; then
    for a in $(sudo $EGREP_FAILED ${EXTLOGS_PREFIX}/keylime_verifier-*.log | $EGREP_UUID); do
        echo "failing agent: $a"
    	sudo grep $a ${EXTLOGS_PREFIX}/keylime_verifier-*.log | tail -n 2
    done
fi

echo
echo "latest log entry:"
if [ $MODE == "DOCKER" ]; then
    cmd="docker logs keylime_verifier | tail -n 1"
elif [ $MODE == "BAREMETAL" ]; then
    cmd="journalctl --no-pager -u keylime_verifier.service | tail -n 1"
elif [ $MODE == "EXTLOGS" ]; then
    cmd="sudo tail -n 1 $(ls -t ${EXTLOGS_PREFIX}/keylime_verifier-*.log | head -n 1)"
fi
if [ "$VERBOSE" == 1 ]; then echo $cmd; fi
eval $cmd

if [[ $MODE == "EXTLOGS" && "$VERBOSE" == 1 ]]; then
    ls -lt ${EXTLOGS_PREFIX}/keylime_verifier-*.log  
fi
