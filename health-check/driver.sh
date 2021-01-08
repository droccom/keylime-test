#!/bin/bash

set -e

if [ $# -lt 3 ]; then
    echo "usage: $0 USER@HOST[,USER@HOST...] BAREMETAL|DOCKER|EXTLOGS LOGTAIL"
    exit
fi

SSH_LIST=$1; shift
MODE=$1; shift
LOGTAIL=$1; shift

echo "> testing SSH connections"
for h in $(echo $SSH_LIST | sed "s/,/ /g")
do
	ssh -q $h exit
	if [ $? -eq 0 ]; then
    		echo "OK: SSH access $h"
	else
    		echo "error: SSH access to $h"
    		exit
	fi
done

if [[ "$MODE" == "EXTLOGS" && -z ${EXTLOGS_PREFIX+x} ]]; then
    echo "EXTLOGS_PREFIX must be defined for $MODE mode"
    exit
fi

logdir=$(mktemp -d)

echo "> upload and run the test script"
for h in $(echo $SSH_LIST | sed "s/,/ /g")
do
	TMPDIR="$(ssh $h mktemp -d)"
	scp klhc.sh $h:$TMPDIR
	logfile=${logdir}/$(echo $h | cut -f 2 -d '@')
	cmd="ssh $h 'export EXTLOGS_PREFIX=\"$EXTLOGS_PREFIX\"; $TMPDIR/klhc.sh $MODE $LOGTAIL' > $logfile"
	echo $cmd && eval $cmd
done
ln -sfn $logdir klhc-logs-latest
