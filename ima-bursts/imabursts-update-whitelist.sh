#!/bin/bash

if [ $# -lt 6 ]; then
    echo "usage: $0 WL_BASE WL_UPDATE EXCLUDE VERIFIER_IP AGENT_IP AGENT_UUID"
    exit
fi

WL_BASE=$1; shift
WL_UPDATE=$1; shift
VERIFIER_IP=$1; shift
AGENT_IP=$1; shift
AGENT_UUID=$1; shift

WL_EXT=$(mktemp)
cat $WL_BASE $WL_UPDATE > $WL_EXT

keylime_tenant \
    --cert /var/lib/keylime/ca \
    -v $KL_VERIFIER_IP \
    --uuid $AGENT_UUID -t $AGENT_IP \
    --whitelist $WL_EXT --exclude $EXCLUDE \
    -c update