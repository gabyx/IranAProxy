# Signal Proxy in GCP VM

Create a VM in Compute Engine in Google Cloud and installs the Signal TLS proxy.

Create a `.env` file and replace values, especially set the `PROXY_DOMAIN`. You
can get a domain for some bucks by any provider in your country.

Then use

```shell
./create-vm.sh [--delete]
```

to create the proxy.

Point the domain `PROXY_DOMAIN` to the global IP which is printed at the end.
