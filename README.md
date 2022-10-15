# Signal Proxy in GCP VM

Create a VM in Compute Engine in Google Cloud and installs the Signal TLS proxy.

Create a `.env` file and replace values, especially set the `PROXY_DOMAIN`. then
use

```shell
./create-vm.sh [--delete]
```

to create the proxy. Then use `