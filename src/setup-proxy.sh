#!/usr/bin/env bash
DIR="$(cd "$(dirname "$0")" >/dev/null 2>&1 && pwd)"

set -e
set -u

die() {
  echo "!! " "$@" >&2
  exit 1
}
cd "$DIR"

sudo apt-get install \
  ca-certificates \
  curl \
  gnupg \
  lsb-release

sudo mkdir -p /etc/apt/keyrings
sudo rm -rf /etc/apt/keyrings/docker.gpg
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --yes --dearmor -o /etc/apt/keyrings/docker.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null

sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin docker-compose git

if [ ! -d "Signal-TLS-Proxy" ]; then
  git clone https://github.com/signalapp/Signal-TLS-Proxy.git ~/Signal-TLS-Proxy
  cd ~/Signal-TLS-Proxy
  sudo ./init-certificate.sh
  sudo docker-compose up --detach
else
  cd ~/Signal-TLS-Proxy
  sudo git pull
  sudo docker-compose down
  sudo docker-compose up --detach
fi
