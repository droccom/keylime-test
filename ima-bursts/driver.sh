BURST_LEN=10
BURST_CNT=2

if [ $# -lt 4 ]; then
    echo "usage: $0 TENANT_IP VERIFIER_IP AGENT_IP AGENT_UUID"
    exit
fi

TENANT_IP=$1; shift
VERIFIER_IP=$1; shift
AGENT_IP=$1; shift
AGENT_UUID=$1; shift

echo "> testing SSH connections"
ssh -q root@$TENANT_IP exit
if [ ! $? -eq 0 ]; then
    echo "error: cannot SSH to tenant at $TENANT_IP"
    exit
fi
ssh -q root@$AGENT_IP exit
if [ ! $? -eq 0 ]; then
    echo "error: cannot SSH to agent at $AGENT_IP"
    exit
fi

echo "> generating the executables and whitelist"
if [ ! -f imabursts-execs.tar.gz ]; then
    tmp=$(mktemp -d)
    cd $tmp
    rm -f imabursts-whitelist.txt
    for i in $(seq 1 $(($BURST_LEN * $BURST_CNT))); do
        echo "#!/bin/bash" > helloworld$i
        echo "echo hello, world number $i!" >> helloworld$i
        chmod u+x helloworld$i
        sha1sum helloworld$i \
            | sed "s/helloworld/\/usr\/local\/bin\/helloworld/" \
            >> imabursts-whitelist.txt
    done
    tar -cf imabursts-execs.tar.gz helloworld*
    cd -
    mv $tmp/imabursts-execs.tar.gz $tmp/imabursts-whitelist.txt .
    rm -rf $tmp
else
    echo "> INFO: using cached executables"
fi

if [ ! grep imabursts-fire imabursts-whitelist.txt ]; then
    echo "> adding imabursts-fire entry to the whitelist"
    sha1sum imabursts-fire.sh \
            | sed "s/imabursts-fire\.sh/\/usr\/local\/bin\/imabursts-fire/" \
            >> imabursts-whitelist.txt
fi

echo "> uploading the whitelist to the tenant"
scp imabursts-whitelist.txt root@$TENANT_IP:

echo "> uploading and launching the update script on the tenant"
scp imabursts-update-whitelist.sh root@$TENANT_IP:
ssh root@$TENANT_IP ./imabursts-update-whitelist.sh \
    imabursts-whitelist.txt \
    $VERIFIER_IP $AGENT_IP $AGENT_UUID

# TODO refine
echo "wait until whitelist has been updated"
sleep 10

echo "> uploading and launching the executables on the agent"
scp imabursts-execs.tar.gz imabursts-fire.sh root@$AGENT_IP:
ssh root@$AGENT_IP tar -xf imabursts-execs.tar.gz -C /usr/local/bin
ssh root@$AGENT_IP mv ./imabursts-fire.sh /usr/local/bin/imabursts-fire
# ssh root@$AGENT_IP imabursts-fire helloworld $BURST_LEN $BURST_CNT
