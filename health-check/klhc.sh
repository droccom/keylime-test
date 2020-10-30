#!/bin/bash

set -e

if [ $# -lt 2 ]; then
    echo "usage: $0 BAREMETAL|DOCKER|EXTLOGS LOGTAIL"
    exit
fi

MODE=$1; shift
LOGTAIL=$1; shift

if [ $MODE == "DOCKER" ]; then
    CMD_PREFIX="docker logs keylime_verifier" 
    CMD_ADDED_AGENTS="$CMD_PREFIX | grep \"adding agent\" | awk '{print \$21}'"
elif [ $MODE == "BAREMETAL" ]; then
    CMD_PREFIX="journalctl --no-pager -u keylime_verifier.service" 
    CMD_ADDED_AGENTS="$CMD_PREFIX| grep \"adding agent\" | awk '{print \$16}'"
elif [ $MODE == "EXTLOGS" ]; then
    if [[ -z ${EXTLOGS_PREFIX+x} ]]; then
        echo "EXTLOGS_PREFIX must be defined for $MODE mode"
        exit
    fi
    CMD_ADDED_AGENTS="sudo grep \"adding agent\" ${EXTLOGS_PREFIX}/keylime_verifier-*.log | awk '{print \$21}'"
fi

echo "registered agents:"
cmd="$CMD_ADDED_AGENTS | sort | uniq | wc -l"
eval $cmd

echo
echo "healthy agents over latest $LOGTAIL per-verifier IMA logs:"
if [ $MODE == "DOCKER" ]; then
    cmd="${CMD_PREFIX} | grep \"Checking IMA\" | tail -n $LOGTAIL | awk '{print \$14}' | sort | uniq | wc -l"
elif [ $MODE == "BAREMETAL" ]; then
    cmd="${CMD_PREFIX} | grep \"Checking IMA\" | tail -n $LOGTAIL | awk '{print \$9}' | sort | uniq | wc -l"
elif [ $MODE == "EXTLOGS" ]; then
    cmd="sudo tail -n $LOGTAIL ${EXTLOGS_PREFIX}/keylime_verifier-*.log | grep \"Checking IMA\" | awk '{print \$19}' | sort | uniq | wc -l"
fi
eval $cmd

echo
echo "failed agents:"
if [ $MODE == "DOCKER" ]; then
    for a in $($CMD_PREFIX | grep "failed, stopping polling" | awk '{print $9}'); do
        echo "failing agent: $a"
    	${CMD_PREFIX} | grep $a | tail -n 2
    done
elif [ $MODE == "BAREMETAL" ]; then
    for a in $($CMD_PREFIX | grep "failed, stopping polling" | awk '{print $4}'); do
        echo "failing agent: $a"
    	${CMD_PREFIX} | grep $a | tail -n 2
    done
elif [ $MODE == "EXTLOGS" ]; then
    for a in $(sudo grep "failed, stopping polling" ${EXTLOGS_PREFIX}/keylime_verifier-*.log | awk '{print $9}'); do
        echo "failing agent: $a"
    	sudo grep $a ${EXTLOGS_PREFIX}/keylime_verifier-*.log | tail -n 2
    done
fi

echo
echo "latest log entry:"
if [[ $MODE == "DOCKER" || $MODE == "BAREMETAL" ]]; then
    cmd="${CMD_PREFIX} | tail -n 1"
elif [ $MODE == "EXTLOGS" ]; then
    cmd="sudo tail -n 1 ${EXTLOGS_PREFIX}/keylime_verifier-*.log | tail -n 1"
fi
eval $cmd
