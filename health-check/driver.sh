#!/bin/bash

set -e

if [ $# -lt 3 ]; then
    echo "usage: $0 [USER@]VERIFIER_IP BAREMETAL|DOCKER|EXTLOGS LOGTAIL"
    exit
fi

SSH_VERIFIER=$1; shift
MODE=$1; shift
LOGTAIL=$1; shift

echo "> testing SSH connections"
ssh -q $SSH_VERIFIER exit
if [ $? -eq 0 ]; then
    echo "OK: SSH access $SSH_VERIFIER"
else
    echo "error: SSH access to $SSH_VERIFIER"
    exit
fi

if [[ "$MODE" == "EXTLOGS" && -z ${EXTLOGS_PREFIX+x} ]]; then
    echo "EXTLOGS_PREFIX must be defined for $MODE mode"
    exit
fi

echo "> uploading and launching the test script on the verifier"
TMPDIR="$(ssh $SSH_VERIFIER mktemp -d)"
scp klhc.sh $SSH_VERIFIER:$TMPDIR
logfile=$(mktemp)
cmd="ssh $SSH_VERIFIER 'export EXTLOGS_PREFIX=\"$EXTLOGS_PREFIX\"; $TMPDIR/klhc.sh $MODE $LOGTAIL' > $logfile"
echo $cmd && eval $cmd
ln -sf $logfile klhc-latest.log
