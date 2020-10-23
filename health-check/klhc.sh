#!/bin/bash

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
    CMD_PREFIX="sudo cat /var/log/dockerlfs/keylime_verifier-*.log" 
    CMD_ADDED_AGENTS="$CMD_PREFIX | grep \"adding agent\" | awk '{print \$21}'"
fi

echo "deployed agents:"
cmd="$CMD_ADDED_AGENTS | sort | uniq | wc -l"
echo $cmd && eval $cmd

echo
echo "healthy agents over latest $LOGTAIL IMA logs:"
cmd="${CMD_PREFIX} | grep \"Checking IMA\" | tail -n $LOGTAIL | awk '{print \$14}' | sort | uniq | wc -l"
echo $cmd && eval $cmd

echo
echo "failed agents:"
for a in $($CMD_PREFIX | grep "failed, stopping polling" | awk '{print $9}'); do
    echo "failing agent: $a"
    ${CMD_PREFIX} | grep $a | tail -n 2
done

echo
echo "latest log entry:"
${CMD_PREFIX} | tail -n 1

