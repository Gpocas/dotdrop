#!/usr/bin/env bash
# Recria MCP servers globais que NAO sao versionados via ~/.claude.json
# (esse arquivo guarda tambem oauth/machine id, entao nao e rastreado pelo dotdrop).
#
# Uso:
#   ./scripts/setup-mcp.sh
#
# Servers configurados: inkdrop, axiom, jaylog, ai-memory (Claude Code e opencode).
# Para o opencode, os mesmos servers sao gravados em ~/.config/opencode/opencode.jsonc
# (chave "mcp"), reaproveitando os valores acima.
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

# --- ai-memory (servidor remoto na VM aimemory-vm) ---
# MCP em ~/.claude.json (token embutido, por isso fora do dotdrop) e hooks em
# ~/.claude/settings.json (sem segredo: o token fica em ~/.local/share/ai-memory/auth-token).
# Infra do servidor: scripts/ai-memory-server/README.md
AI_MEMORY_SECRETS_FILE="$SCRIPT_DIR/secrets/ai-memory.env"

if [ -f "$AI_MEMORY_SECRETS_FILE" ]; then
  # shellcheck disable=SC1090
  source "$AI_MEMORY_SECRETS_FILE"
else
  echo "Arquivo $AI_MEMORY_SECRETS_FILE nao encontrado, pedindo valores interativamente."
  read -r -p "AI_MEMORY_URL (ex: https://host.sslip.io): " AI_MEMORY_URL
  read -r -s -p "AI_MEMORY_TOKEN: " AI_MEMORY_TOKEN
  echo
fi

: "${AI_MEMORY_URL:?defina AI_MEMORY_URL}"
: "${AI_MEMORY_TOKEN:?defina AI_MEMORY_TOKEN}"

"$SCRIPT_DIR/ai-memory-install-cli.sh"
AI_MEMORY_BIN="${AI_MEMORY_BIN:-$HOME/.local/bin/ai-memory}"

"$AI_MEMORY_BIN" install-mcp --client claude-code \
  --server-url "$AI_MEMORY_URL" --auth-token "$AI_MEMORY_TOKEN" --apply >/dev/null
"$AI_MEMORY_BIN" install-hooks --agent claude-code \
  --server-url "$AI_MEMORY_URL" --auth-token "$AI_MEMORY_TOKEN" --apply >/dev/null

echo "MCP e hooks ai-memory configurados (reinicie o Claude Code)."

# --- opencode ---
# Escreve os mesmos MCPs em ~/.config/opencode/opencode.jsonc (preserva outras chaves).
OPENCODE_CONFIG="${OPENCODE_CONFIG:-$HOME/.config/opencode/opencode.jsonc}"
mkdir -p "$(dirname "$OPENCODE_CONFIG")"

INKDROP_LOCAL_SERVER_URL="$INKDROP_LOCAL_SERVER_URL" \
INKDROP_LOCAL_USERNAME="$INKDROP_LOCAL_USERNAME" \
INKDROP_LOCAL_PASSWORD="$INKDROP_LOCAL_PASSWORD" \
JAYLOG_URL="$JAYLOG_URL" \
AI_MEMORY_URL="$AI_MEMORY_URL" \
AI_MEMORY_TOKEN="$AI_MEMORY_TOKEN" \
python3 - "$OPENCODE_CONFIG" <<'PY'
import json, os, re, sys

path = sys.argv[1]
cfg = {"$schema": "https://opencode.ai/config.json"}
if os.path.exists(path):
    raw = open(path).read()
    # jsonc: remove comentarios de linha inteira e virgulas finais
    raw = re.sub(r"^\s*//.*$", "", raw, flags=re.M)
    raw = re.sub(r",(\s*[}\]])", r"\1", raw)
    cfg.update(json.loads(raw))

e = os.environ
cfg.setdefault("mcp", {}).update({
    "inkdrop": {
        "type": "local",
        "command": ["npx", "-y", "@inkdropapp/mcp-server"],
        "enabled": True,
        "environment": {
            "INKDROP_LOCAL_SERVER_URL": e["INKDROP_LOCAL_SERVER_URL"],
            "INKDROP_LOCAL_USERNAME": e["INKDROP_LOCAL_USERNAME"],
            "INKDROP_LOCAL_PASSWORD": e["INKDROP_LOCAL_PASSWORD"],
        },
    },
    "axiom": {
        "type": "local",
        "command": ["npx", "-y", "mcp-remote", "https://mcp.axiom.co/mcp"],
        "enabled": True,
    },
    "jaylog": {
        "type": "local",
        "command": ["npx", "-y", "jaylog-mcp"],
        "enabled": True,
        "environment": {"JAYLOG_URL": e["JAYLOG_URL"]},
    },
    "ai-memory": {
        "type": "remote",
        "url": e["AI_MEMORY_URL"].rstrip("/") + "/mcp",
        "enabled": True,
        "headers": {"Authorization": "Bearer " + e["AI_MEMORY_TOKEN"]},
    },
})
# remove entrada antiga com nome diferente
cfg["mcp"].pop("inkdrop-mcp-server", None)

with open(path, "w") as f:
    json.dump(cfg, f, indent=2)
    f.write("\n")
os.chmod(path, 0o600)
PY

echo "MCPs configurados no opencode ($OPENCODE_CONFIG)."
