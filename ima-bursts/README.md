# Keylime test: ima-bursts

This test performs a stress test of the IMA attestation machinery in a Keylime deployment.
When fired on a Keylime agent, it triggers bursts of execution of IMA-monitored binaries. This should stimulate possible timing issues in the verifier when comparing IMA logs with values of TPM PCR 10.

## Prerequisites and Notes

This test assumes the following conditions:

- Keylime components are running in Docker containers (supporting non-dockerized deployments is work in progress)
- the Keylime deployment is complete, i.e. the verifier is receiving IMA logs from all the agents (this can be tested with the `health-check` tool)

*Note*: this test modifies the whitelist associated with the agent performing the bursts; if you attempt to execute the test before the deployment is complete, the resulting system would result in an inconsistent state.

## Operations

The top-level script is `driver.sh` and it is operated as follows:

```bash
./driver.sh user@100.64.8.10 100.64.8.10 100.64.8.17 88A83D79-DE8E-50B3-A922-78DF01A35CD2
```

- `user@100.64.8.10` is the SSH command line to access the tenant
- `100.64.8.10` is the IP addres of the verifier
- `100.64.8.17` is the IP address of the agent which will execute the bursts

Once the test is completed, you can check the status of the deployment with the `health-check` tool.
