#!/bin/bash

if [ $# -lt 2 ]; then
    echo "usage: $0 BAREMETAL|DOCKER LOGTAIL"
    exit
fi

MODE=$1; shift
LOGTAIL=$1; shift

if [ $MODE == "DOCKER" ]; then
    LOGCMD="docker logs keylime_verifier"
else
    LOGCMD="journalctl --no-pager -u keylime_verifier.service"
fi

echo "deployed agents:"
${LOGCMD} | grep "adding agent" | sort | uniq | wc -l

echo
echo "healthy agents on latest $nht IMA logs:"
${LOGCMD} | grep "Checking IMA" | tail -n $LOGTAIL | awk '{print $14}' | sort | uniq

echo
echo "failed agents:"
for a in $(docker logs keylime_verifier | grep "failed, stopping polling" | awk '{print $9}'); do
    echo "failing agent: $a"
    ${LOGCMD} | grep $a | tail -n 2
done
