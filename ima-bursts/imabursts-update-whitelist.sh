#!/bin/bash

# this runs on the agent

if [ $# -lt 4 ]; then
    echo "usage: $0 WL_UPDATE VERIFIER_IP AGENT_IP AGENT_UUID"
    exit
fi

WL_UPDATE=$1; shift
VERIFIER_IP=$1; shift
AGENT_IP=$1; shift
AGENT_UUID=$1; shift

WL_BASE=/tmp/whitelist_${AGENT_UUID}.txt
WL_EXCLUDE="/ima_exclude.txt" # on the tenant

# copy whitelist from container
WL_BASE_HOST=$(mktemp)
docker cp keylime_deployer:$WL_BASE $WL_BASE_HOST
echo "[$0] original whitelist entries: $(wc -l $WL_BASE_HOST)"

# sanitize whitelist
WL_CLEANED_HOST=$(mktemp)
cat $WL_BASE_HOST \
    | tr -cd '\11\12\15\40-\176' \
    | env LANG=C grep -v "["$'\x80'-$'\xff'"]" \
    > $WL_CLEANED_HOST
rm $WL_BASE_HOST
unset WL_BASE_HOST
echo "[$0] cleaned whitelist entries: $(wc -l $WL_CLEANED_HOST)"

# extend whitelist
WL_EXT=$(mktemp)
sed -i '/helloworld/ d' $WL_CLEANED_HOST
cat $WL_CLEANED_HOST $WL_UPDATE > $WL_EXT
echo "[$0] whitelist update entries: $(wc -l $WL_UPDATE)"
wc -l $WL_EXT
echo "[$0] extended whitelist entries: $(wc -l $WL_EXT)"
rm $WL_CLEANED_HOST
unset WL_CLEANED_HOST

# copy extended whitelist to container
WL_EXT_DOCKER=$(docker exec keylime_deployer mktemp)
docker cp $WL_EXT keylime_deployer:$WL_EXT_DOCKER
rm $WL_EXT
unset WL_EXT

KL_SECRET_FILE=$(docker exec keylime_deployer mktemp)
cmd="docker exec keylime_deployer keylime_tenant \
    -f $KL_SECRET_FILE \
    -v $VERIFIER_IP \
    --uuid $AGENT_UUID -t $AGENT_IP \
    --whitelist $WL_EXT_DOCKER --exclude $WL_EXCLUDE \
    -c update"

$cmd
