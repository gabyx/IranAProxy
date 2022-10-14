#!/usr/bin/env bash
DIR="$(cd "$(dirname "$0")" >/dev/null 2>&1 && pwd)"

set -e
set -u

die() {
    echo "!! " "$@" >&2
    exit 1
}
function isVMRunning() {
    [ -n "$(gcloud compute instances list --filter="name=$VM_NAME")" ] && return 0
    return 1
}

cd "$DIR"

echo "Source env file."
. $DIR/.env
delete=false && [ "${1:-}" = "--delete" ] && delete="true"

gcloud config set project "$GCP_PROJECT_NAME"
gcloud config set compute/zone "$VM_ZONE"
gcloud config set compute/region "$VM_REGION"
gcloud config set disable_prompts true
gcpAccountName=$(gcloud auth list --filter=status:ACTIVE --format="value(account)")

[ "$delete" = "true" ] && {
    echo "Deleting VM '$VM_NAME'"
    gcloud compute instances delete "$VM_NAME" || die "Could not delete '$VM_NAME'"
}

if ! isVMRunning; then
    if ! gcloud compute addresses describe --region "$VM_REGION" "$VM_NAME-ip" &>/dev/null; then
        echo "Create IP"
        gcloud compute addresses create "$VM_NAME-ip" \
            --region "$VM_REGION"
    fi
    externalIP=$(gcloud compute addresses describe --region "$VM_REGION" "$VM_NAME-ip" --format='get(address)')
    echo "External  IP '$externalIP'"

    echo "Create VM '$VM_NAME'."
    gcloud compute instances create "$VM_NAME" \
        --project=iranaproxy \
        --zone="$VM_ZONE" \
        --address="$externalIP" \
        --machine-type=e2-micro \
        --tags=http-server,https-server \
        --create-disk=auto-delete=yes,boot=yes,device-name=instance-1,image=projects/ubuntu-os-cloud/global/images/ubuntu-2204-jammy-v20221011,mode=rw,size=10,type=projects/iranaproxy/zones/me-west1-a/diskTypes/pd-balanced ||
        die "Could not create '$VM_NAME'"
else
    echo "VM $VM_NAME is alread running."
fi

echo "Create SSH keypair..."
sshFile="$DIR/$VM_SSH_FILE"
if [ ! -f "$sshFile" ]; then
    mkdir -p "$DIR/.ssh"
    rm -rf "$sshFile"
    ssh-keygen -t rsa -N "$VM_PASSPHRASE" -C "$gcpAccountName" -f "$sshFile"
fi

echo "Copy setup scripts to VM"
gcloud compute scp --ssh-key-file "$sshFile" "./src/setup-proxy.sh" "$VM_NAME:"~/setup-proxy.sh

gcloud compute ssh --ssh-key-file "$sshFile" \
    --command 'bash ~/setup-proxy.sh' "$VM_NAME"

formatArg="get(networkInterfaces[0].accessConfigs[0].natIP)"
externalIp=$(gcloud compute instances describe "$VM_NAME" --format "$formatArg")

echo "Your Signal Proxy is running. Share this with: https://signal.tube/#$externalIp"
