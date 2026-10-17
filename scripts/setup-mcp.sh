#!/usr/bin/env bash
# Recria MCP servers globais que NAO sao versionados via ~/.claude.json
# (esse arquivo guarda tambem oauth/machine id, entao nao e rastreado pelo dotdrop).
#
# Uso:
#   ./scripts/setup-mcp.sh
#
# Servers configurados: inkdrop, axiom, jaylog.
#
# Os valores vem de scripts/secrets/<server>.env (nao versionados - veja os
# arquivos .env.example). Se o arquivo nao existir, pede os valores
# interativamente. O axiom nao precisa de segredo (OAuth via mcp-remote: o login
# e feito no navegador no primeiro uso).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INKDROP_SECRETS_FILE="$SCRIPT_DIR/secrets/inkdrop.env"
JAYLOG_SECRETS_FILE="$SCRIPT_DIR/secrets/jaylog.env"

# --- inkdrop ---
if [ -f "$INKDROP_SECRETS_FILE" ]; then
  # shellcheck disable=SC1090
  source "$INKDROP_SECRETS_FILE"
else
  echo "Arquivo $INKDROP_SECRETS_FILE nao encontrado, pedindo valores interativamente."
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

# --- axiom ---
claude mcp remove axiom -s user >/dev/null 2>&1 || true

claude mcp add axiom -s user \
  -- npx -y mcp-remote https://mcp.axiom.co/mcp

echo "MCP axiom configurado (escopo: user)."

# --- jaylog ---
if [ -f "$JAYLOG_SECRETS_FILE" ]; then
  # shellcheck disable=SC1090
  source "$JAYLOG_SECRETS_FILE"
else
  echo "Arquivo $JAYLOG_SECRETS_FILE nao encontrado, pedindo valores interativamente."
  read -r -p "JAYLOG_URL: " JAYLOG_URL
fi

: "${JAYLOG_URL:?defina JAYLOG_URL}"

claude mcp remove jaylog -s user >/dev/null 2>&1 || true

claude mcp add jaylog -s user \
  -e JAYLOG_URL="$JAYLOG_URL" \
  -- npx -y jaylog-mcp

echo "MCP jaylog configurado (escopo: user)."
