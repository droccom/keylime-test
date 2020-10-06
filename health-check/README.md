```bash
./driver.sh user@127.0.0.1 DOCKER 20
```
- `user@127.0.0.1` is the SSH command line to access the verifier node
- `DOCKER` denotes Keylime components are running in docker containers (alt. `BAREMETAL`)
- `20` is the tail length at which logs are scanned for unhealthy agents (rule of thumb: twice the number of agents)
