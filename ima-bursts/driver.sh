#!/bin/bash

BURST_LEN=10
BURST_CNT=2
BURST_WAIT_LIMIT=10

IMA_WHITELIST_PATH="/KL/keylime/archive/ima/whitelist.txt" # on the tenant
IMA_EXCLUDE_PATH="/ima_exclude.txt" # on the tenant

if [ $# -lt 4 ]; then
    echo "usage: $0 [user@]TENANT_HOST VERIFIER_IP AGENT_IP AGENT_UUID"
    exit
fi

TENANT_HOST=$1; shift
VERIFIER_IP=$1; shift
AGENT_IP=$1; shift
AGENT_UUID=$1; shift

echo "> testing SSH connections"
ssh -q $TENANT_HOST exit
if [ $? -eq 0 ]; then
    echo "OK: SSH access $TENANT_HOST"
else
    echo "error: SSH access $TENANT_HOST"
    exit
fi

echo "> generating the executables and whitelist"
tmp=$(mktemp -d)
cd $tmp
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
unset tmp

echo "> uploading the whitelist to the tenant"
scp imabursts-whitelist.txt $TENANT_HOST:

echo "> uploading and launching the update script on the tenant"
scp imabursts-update-whitelist.sh $TENANT_HOST:
ssh $TENANT_HOST ./imabursts-update-whitelist.sh \
    $IMA_WHITELIST_PATH imabursts-whitelist.txt \
    $IMA_EXCLUDE_PATH $VERIFIER_IP $AGENT_IP $AGENT_UUID

# TODO refine
echo "> waiting until whitelist has been updated"
sleep 10

echo "> uploading and launching the executables on the agent"
scp imabursts-execs.tar.gz imabursts-fire.sh root@$AGENT_IP:
ssh root@$AGENT_IP tar -xf imabursts-execs.tar.gz -C /usr/local/bin
ssh root@$AGENT_IP ./imabursts-fire.sh \
    /usr/local/bin/helloworld \
    $BURST_LEN $BURST_CNT $BURST_WAIT_LIMIT
