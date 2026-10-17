#!/usr/bin/env bash
# Envia os arquivos desta pasta para a VM e (re)sobe os containers.
# O .env.production NAO e enviado: crie-o na VM a partir de env.production.example.
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"
G=(gcloud compute --project wireguard-492111)
Z=(--zone us-central1-b --tunnel-through-iap --quiet)

"${G[@]}" scp "${Z[@]}" docker-compose.yml Caddyfile aimemory-backup aimemory-backup.service aimemory-backup.timer aimemory-vm:/tmp/
"${G[@]}" ssh aimemory-vm "${Z[@]}" --command '
  set -e
  sudo install -m 0644 /tmp/docker-compose.yml /tmp/Caddyfile /opt/ai-memory/
  sudo install -m 0750 /tmp/aimemory-backup /usr/local/bin/aimemory-backup
  sudo install -m 0644 /tmp/aimemory-backup.service /tmp/aimemory-backup.timer /etc/systemd/system/
  sudo systemctl daemon-reload && sudo systemctl enable --now aimemory-backup.timer
  cd /opt/ai-memory && sudo docker compose up -d'
