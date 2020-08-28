BURST_LEN=10
BURST_CNT=2

IMA_WHITELIST_PATH="~/whitelist.txt" # on the tenant
IMA_EXCLUDE_PATH="~/exclude.txt" # on the tenant

if [ $# -lt 4 ]; then
    echo "usage: $0 TENANT_IP VERIFIER_IP AGENT_IP AGENT_UUID"
    exit
fi

TENANT_IP=$1; shift
VERIFIER_IP=$1; shift
AGENT_IP=$1; shift
AGENT_UUID=$1; shift

echo "> generating the executables"
if [ ! -f imabursts-execs.tar.gz ]; then
    tmp=$(mktemp -d)
    cd $tmp
    for i in $(seq 1 $(($BURST_LEN * $BURST_CNT))); do
        echo "#!/bin/bash" > helloworld$i
        echo "echo hello, world number $i!" >> helloworld$i
        chmod u+x helloworld$i
    done
    tar -cf imabursts-execs.tar.gz helloworld*
    cd -
    mv $tmp/imabursts-execs.tar.gz .
    rm -rf $tmp
else
    echo "> INFO: using cached executables"
fi

echo "> calculating the delta whitelist"
if [ ! -f imabursts-whitelist.txt ]; then
    # TODO
    touch imabursts-whitelist.txt
else
    echo "> INFO: using cached whitelist"
fi

echo "> uploading the whitelist to the tenant"
scp imabursts-whitelist.txt root@$TENANT_IP:

echo "> uploading and launching the update script on the tenant"
scp imabursts-update-whitelist.sh root@$TENANT_IP:
ssh root@$TENANT_IP ./imabursts-update-whitelist.sh \
    $IMA_WHITELIST_PATH imabursts-whitelist.txt \
    $IMA_EXCLUDE_PATH $VERIFIER_IP $AGENT_IP $AGENT_UUID

echo "> uploading and launching the executables on the agent"
scp imabursts-execs.tar.gz imabursts-fire.sh root@$TENANT_IP:
ssh root@$TENANT_IP tar -xf imabursts-execs.tar.gz -C /usr/local/bin
ssh root@$TENANT_IP ./imabursts-fire.sh \
    /usr/local/bin/helloworld \
    $BURST_LEN $BURST_CNT