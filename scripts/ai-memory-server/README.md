# ai-memory server (GCP)

Servidor [ai-memory](https://github.com/akitaonrails/ai-memory) 3.1.0 em HTTPS com bearer token,
para uso pessoal. Cliente (Claude Code): `scripts/setup-mcp.sh` (secao ai-memory).

| Item | Valor |
|---|---|
| Projeto / regiao / zona | `wireguard-492111` / `us-central1` / `us-central1-b` |
| VM | `aimemory-vm` (e2-small, Ubuntu 24.04, Shielded VM, OS Login, sem service account de uso geral) |
| Rede | VPC `aimemory-vpc`, subnet `aimemory-subnet` `10.20.0.0/24`, Cloud NAT `aimemory-nat` |
| IP estatico | `aimemory-ip` = `34.135.252.238` |
| URL | `https://34-135-252-238.sslip.io` (Caddy + Let's Encrypt; sslip.io = DNS gratuito que resolve para o IP) |
| Backup | bucket `gs://wireguard-492111-aimemory-backups` (30 dias), SA `aimemory-backup` so com `objectCreator` |
| Snapshots | policy `aimemory-daily` (07:00 UTC, 7 dias) |

Se o IP estatico mudar, atualize o hostname em `Caddyfile`, `AI_MEMORY_ALLOWED_HOSTS` e `secrets/ai-memory.env`.

## Segredos (NAO ficam no git)
- `/opt/ai-memory/.env.production` na VM (`chmod 600`): modelo em `env.production.example`.
- `scripts/secrets/ai-memory.env` na maquina cliente (gitignored).
- Backups **nao** incluem o `.env.production`: guarde o token e a `GEMINI_API_KEY` no gerenciador de senhas.

## Reconstruir do zero
```bash
P=wireguard-492111; R=us-central1; Z=us-central1-b; B=$P-aimemory-backups; SA=aimemory-backup

# 1. Rede
gcloud services enable iap.googleapis.com --project $P
gcloud compute networks create aimemory-vpc --project $P --subnet-mode=custom
gcloud compute networks subnets create aimemory-subnet --project $P --network aimemory-vpc \
  --region $R --range 10.20.0.0/24 --enable-private-ip-google-access
gcloud compute routers create aimemory-router --project $P --network aimemory-vpc --region $R
gcloud compute routers nats create aimemory-nat --project $P --router aimemory-router --region $R \
  --auto-allocate-nat-external-ips --nat-all-subnet-ip-ranges
gcloud compute addresses create aimemory-ip --project $P --region $R
gcloud compute firewall-rules create aimemory-allow-iap-ssh --project $P --network aimemory-vpc \
  --allow tcp:22 --source-ranges 35.235.240.0/20 --target-tags aimemory
gcloud compute firewall-rules create aimemory-allow-web --project $P --network aimemory-vpc \
  --allow tcp:80,tcp:443 --source-ranges 0.0.0.0/0 --target-tags aimemory

# 2. Backup (bucket + SA que so cria objetos)
gcloud storage buckets create gs://$B --project $P --location $R \
  --uniform-bucket-level-access --public-access-prevention
echo '{"rule":[{"action":{"type":"Delete"},"condition":{"age":30}}]}' > /tmp/lifecycle.json
gcloud storage buckets update gs://$B --lifecycle-file=/tmp/lifecycle.json
gcloud iam service-accounts create $SA --project $P --display-name "ai-memory backup writer"
gcloud storage buckets add-iam-policy-binding gs://$B \
  --member=serviceAccount:$SA@$P.iam.gserviceaccount.com --role=roles/storage.objectCreator

# 3. VM (a SA do backup e anexada na criacao, com scope storage-rw)
gcloud compute instances create aimemory-vm --project $P --zone $Z --machine-type e2-small \
  --network-interface=subnet=aimemory-subnet,address=aimemory-ip,network-tier=PREMIUM \
  --image-family ubuntu-2404-lts-amd64 --image-project ubuntu-os-cloud \
  --boot-disk-size 20GB --boot-disk-type pd-balanced --boot-disk-device-name aimemory-vm \
  --tags aimemory --service-account $SA@$P.iam.gserviceaccount.com --scopes storage-rw \
  --shielded-secure-boot --shielded-vtpm --shielded-integrity-monitoring \
  --metadata enable-oslogin=TRUE,block-project-ssh-keys=TRUE
gcloud compute resource-policies create snapshot-schedule aimemory-daily --project $P --region $R \
  --max-retention-days 7 --daily-schedule --start-time 07:00 --on-source-disk-delete keep-auto-snapshots
gcloud compute disks add-resource-policies aimemory-vm --project $P --zone $Z --resource-policies aimemory-daily

# 4. SO e aplicacao (SSH por IAP; exige roles/iap.tunnelResourceAccessor + osAdminLogin)
SSH=(gcloud compute ssh aimemory-vm --project $P --zone $Z --tunnel-through-iap --quiet)
"${SSH[@]}" --command "bash -s" < setup-vm.sh
# crie /opt/ai-memory/.env.production na VM (veja env.production.example), depois:
./deploy-files.sh
```

## Operacao
```bash
SSH="gcloud compute ssh aimemory-vm --project wireguard-492111 --zone us-central1-b --tunnel-through-iap"
$SSH                                             # shell na VM
$SSH --command "sudo docker logs --tail 50 ai-memory"
$SSH --command "sudo systemctl start aimemory-backup.service"   # backup manual
gcloud storage ls -l gs://wireguard-492111-aimemory-backups/
```
- **Atualizar versao:** troque a tag em `docker-compose.yml`, rode `./deploy-files.sh`, confira o health.
- **Ativar/trocar Gemini:** modelo atual `gemini-3.8-flash` (`AI_MEMORY_LLM_MODEL`); edite `.env.production` na VM e `sudo docker compose up -d --force-recreate ai-memory`.
- **Restore:** baixe `ai-memory-<ts>.tar.gz`, extraia em um diretorio vazio (`wiki/`, `db/`) e monte em `/data`
  de um container `akitaonrails/ai-memory:<tag>`. O `caddy-<ts>.tar.gz` guarda certificado e conta ACME.

## Limitacoes conhecidas
- O backup cobre `wiki/`, `db/` e config; o `raw/` (ledger de observacoes) nao entra.
- Parar a VM (ex.: trocar service account) tira o servico do ar por 1-2 min.
- Papel `owner` no projeto foi necessario so para liberar IAP/OS Login; da para reduzir depois.
