#!/usr/bin/env bash
# Prepara o SO da VM (Ubuntu 24.04): updates automaticos, Docker, ufw, sshd endurecido.
# Rode NA VM:  gcloud compute ssh aimemory-vm ... --tunnel-through-iap --command "bash -s" < setup-vm.sh
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive
sudo apt-get update -qq && sudo apt-get -y -qq upgrade
sudo apt-get -y -qq install unattended-upgrades ufw ca-certificates curl
printf 'APT::Periodic::Update-Package-Lists "1";\nAPT::Periodic::Unattended-Upgrade "1";\n' \
  | sudo tee /etc/apt/apt.conf.d/20auto-upgrades >/dev/null

sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
  | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
sudo apt-get update -qq
sudo apt-get -y -qq install docker-ce docker-ce-cli containerd.io docker-compose-plugin

sudo ufw default deny incoming; sudo ufw default allow outgoing
sudo ufw allow 22/tcp; sudo ufw allow 80/tcp; sudo ufw allow 443/tcp
sudo ufw --force enable

printf 'PasswordAuthentication no\nPermitRootLogin no\nKbdInteractiveAuthentication no\n' \
  | sudo tee /etc/ssh/sshd_config.d/99-hardening.conf >/dev/null
sudo sshd -t && sudo systemctl reload ssh

sudo mkdir -p /opt/ai-memory && sudo chown "$USER" /opt/ai-memory
