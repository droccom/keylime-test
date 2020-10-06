# Keylime test: health-check

This test monitors the health status of a Keylime deployment.

## Operations

The top-level script is `driver.sh` and it is operated as follows: 

```bash
./driver.sh user@100.64.8.10 DOCKER 20
```

- `user@100.64.8.10` is the SSH command line to access the verifier
- `DOCKER` denotes Keylime components are running in docker containers (alt. `BAREMETAL` to denote they run as plain services)
- `20` is the tail length at which logs are scanned for unhealthy agents (rule of thumb: twice the number of agents)

The output is continuously updated (i.e. `watch`) and looks like the following:

```console
Every 2.0s: /tmp/tmp.bVETHU6v2A/klhc.sh DOCKER 20    cssf8-uc: Tue Oct  6 18:27:46 2020

deployed agents:
10

healthy agents over latest 20 IMA logs:
10

failed agents:

latest log entry:
2020-10-06 18:27:47.797 - keylime.tpm - INFO - Checking IMA measurement list on agent:
D6FB1297-9A82-59AA-BDD0-7142E2FEC3BA
```

The output includes:

- the number of healthy/deployed agents
- the log portions reporting failed agents (empty in the screenshot above)
- the latest entry of the verifier's log, to double-check everything is up and running

We say a deployment is *fully healthy* if both:

- `deployed agents` = `healthy agents`, i.e. no agents failed
- `deployed agents` is the total number of agents (i.e. deployment is complete)
