#!/usr/bin/env bash
# Instala o CLI ai-memory (release oficial, checksum SHA-256 verificado pelo proprio
# install.sh) em ~/.local/bin. Nao cria servidor local (nao rodamos `ai-memory setup`).
#
# Uso:
#   ./scripts/ai-memory-install-cli.sh            # versao fixada abaixo
#   AI_MEMORY_VERSION=3.2.0 ./scripts/ai-memory-install-cli.sh
set -euo pipefail

AI_MEMORY_VERSION="${AI_MEMORY_VERSION:-3.1.0}"
export AI_MEMORY_VERSION

if command -v ai-memory >/dev/null 2>&1 && [ "$(ai-memory --version | awk '{print $2}')" = "$AI_MEMORY_VERSION" ]; then
  echo "ai-memory $AI_MEMORY_VERSION ja instalado."
  exit 0
fi

curl -fsSL "https://github.com/akitaonrails/ai-memory/releases/download/v${AI_MEMORY_VERSION}/install.sh" | sh
"$HOME/.local/bin/ai-memory" --version
echo "Garanta que ~/.local/bin esta no PATH."
