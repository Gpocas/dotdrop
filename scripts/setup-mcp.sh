#!/usr/bin/env bash
# Recria MCP servers globais que NAO sao versionados via ~/.claude.json
# (esse arquivo guarda tambem oauth/machine id, entao nao e rastreado pelo dotdrop).
#
# Uso:
#   ./scripts/setup-mcp.sh
#
# As credenciais vem de scripts/secrets/inkdrop.env (nao versionado - veja
# scripts/secrets/inkdrop.env.example). Se o arquivo nao existir, pede os
# valores interativamente.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SECRETS_FILE="$SCRIPT_DIR/secrets/inkdrop.env"

if [ -f "$SECRETS_FILE" ]; then
  # shellcheck disable=SC1090
  source "$SECRETS_FILE"
else
  echo "Arquivo $SECRETS_FILE nao encontrado, pedindo valores interativamente."
  read -r -p "INKDROP_LOCAL_SERVER_URL (ex: http://localhost:PORTA): " INKDROP_LOCAL_SERVER_URL
  read -r -p "INKDROP_LOCAL_USERNAME: " INKDROP_LOCAL_USERNAME
  read -r -s -p "INKDROP_LOCAL_PASSWORD: " INKDROP_LOCAL_PASSWORD
  echo
fi

: "${INKDROP_LOCAL_SERVER_URL:?defina INKDROP_LOCAL_SERVER_URL}"
: "${INKDROP_LOCAL_USERNAME:?defina INKDROP_LOCAL_USERNAME}"
: "${INKDROP_LOCAL_PASSWORD:?defina INKDROP_LOCAL_PASSWORD}"

claude mcp remove inkdrop -s user >/dev/null 2>&1 || true

claude mcp add inkdrop -s user \
  -e INKDROP_LOCAL_SERVER_URL="$INKDROP_LOCAL_SERVER_URL" \
  -e INKDROP_LOCAL_USERNAME="$INKDROP_LOCAL_USERNAME" \
  -e INKDROP_LOCAL_PASSWORD="$INKDROP_LOCAL_PASSWORD" \
  -- npx -y @inkdropapp/mcp-server

echo "MCP inkdrop configurado (escopo: user)."
