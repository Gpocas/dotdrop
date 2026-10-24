#!/usr/bin/env python3
"""Recria os MCP servers globais do Claude Code e do opencode.

~/.claude.json guarda tambem oauth/machine id, entao nao e rastreado pelo
dotdrop; este script recria os MCPs nele (via `claude mcp add`) e grava os
mesmos servers em ~/.config/opencode/opencode.jsonc a partir de uma unica
tabela (SERVERS).

Uso:
    ./scripts/setup-mcp.py [--client claude|opencode|all] [--dry-run]

Os valores vem de scripts/secrets/<server>.env (nao versionados - veja os
.env.example). Se o arquivo nao existir, pede interativamente. O axiom nao
precisa de segredo (OAuth via mcp-remote: login no navegador no primeiro uso).
Infra do ai-memory: scripts/ai-memory-server/README.md
"""
import argparse
import getpass
import json
import os
import re
import subprocess
import sys
from pathlib import Path

SCRIPT_DIR = Path(__file__).resolve().parent
SECRETS_DIR = SCRIPT_DIR / "secrets"
OPENCODE_CONFIG = Path(
    os.environ.get("OPENCODE_CONFIG", Path.home() / ".config/opencode/opencode.jsonc")
)
AI_MEMORY_BIN = Path(os.environ.get("AI_MEMORY_BIN", Path.home() / ".local/bin/ai-memory"))
# Politica de captura dos hooks: projeto pela raiz do repo, so captura repos com
# .ai-memory.toml (allowlist) e inclui o trecho final da resposta do assistente
# (o servidor precisa de AI_MEMORY_CAPTURE_ASSISTANT=true).
HOOK_CAPTURE_FLAGS = ["--project-strategy", "repo-root", "--capture-mode", "allowlist", "--capture-assistant"]

# Cada server: variaveis necessarias (nome -> (prompt, secreta?)), e o comando
# local ou a URL remota. "env" lista quais variaveis vao para o ambiente do server.
SERVERS = {
    "inkdrop": {
        "vars": {
            "INKDROP_LOCAL_SERVER_URL": ("INKDROP_LOCAL_SERVER_URL (ex: http://localhost:PORTA)", False),
            "INKDROP_LOCAL_USERNAME": ("INKDROP_LOCAL_USERNAME", False),
            "INKDROP_LOCAL_PASSWORD": ("INKDROP_LOCAL_PASSWORD", True),
        },
        "command": ["npx", "-y", "@inkdropapp/mcp-server"],
        "env": ["INKDROP_LOCAL_SERVER_URL", "INKDROP_LOCAL_USERNAME", "INKDROP_LOCAL_PASSWORD"],
    },
    "axiom": {
        "vars": {},
        "command": ["npx", "-y", "mcp-remote", "https://mcp.axiom.co/mcp"],
        "env": [],
    },
    "jaylog": {
        "vars": {"JAYLOG_URL": ("JAYLOG_URL", False)},
        "command": ["npx", "-y", "jaylog-mcp"],
        "env": ["JAYLOG_URL"],
    },
    # Remoto na VM aimemory-vm. No Claude Code e instalado pelo proprio binario
    # ai-memory (MCP + hooks, nos dois clientes); o token fica em ~/.claude.json, por isso fora do dotdrop.
    "ai-memory": {
        "vars": {
            "AI_MEMORY_URL": ("AI_MEMORY_URL (ex: https://host.sslip.io)", False),
            "AI_MEMORY_TOKEN": ("AI_MEMORY_TOKEN", True),
        },
        "url": lambda v: v["AI_MEMORY_URL"].rstrip("/") + "/mcp",
        "headers": lambda v: {"Authorization": "Bearer " + v["AI_MEMORY_TOKEN"]},
    },
}


def read_env_file(path: Path) -> dict:
    values = {}
    for line in path.read_text().splitlines():
        line = line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, _, val = line.partition("=")
        values[key.strip()] = val.strip().strip("'\"")
    return values


def load_values(name: str, spec: dict) -> dict:
    """Le secrets/<name>.env; para o que faltar, pergunta no terminal."""
    if not spec["vars"]:
        return {}
    path = SECRETS_DIR / f"{name}.env"
    values = read_env_file(path) if path.exists() else {}
    if not path.exists():
        print(f"Arquivo {path} nao encontrado, pedindo valores interativamente.")
    for var, (prompt, secret) in spec["vars"].items():
        if values.get(var):
            continue
        ask = getpass.getpass if secret else input
        values[var] = ask(f"{prompt}: ").strip()
        if not values[var]:
            sys.exit(f"defina {var}")
    return values


def run(cmd: list, dry_run: bool, check: bool = True, quiet: bool = False) -> None:
    if dry_run:
        print("[dry-run]", " ".join(cmd))
        return
    subprocess.run(
        cmd,
        check=check,
        stdout=subprocess.DEVNULL if quiet else None,
        stderr=subprocess.DEVNULL if quiet and not check else None,
    )


def setup_claude(all_values: dict, dry_run: bool) -> None:
    for name, spec in SERVERS.items():
        values = all_values[name]
        if name == "ai-memory":
            setup_claude_ai_memory(values, dry_run)
            continue
        run(["claude", "mcp", "remove", name, "-s", "user"], dry_run, check=False, quiet=True)
        env_args = [a for var in spec["env"] for a in ("-e", f"{var}={values[var]}")]
        run(["claude", "mcp", "add", name, "-s", "user", *env_args, "--", *spec["command"]], dry_run)
        if not dry_run:
            print(f"MCP {name} configurado no Claude Code (escopo: user).")


def setup_claude_ai_memory(values: dict, dry_run: bool) -> None:
    # MCP em ~/.claude.json e hooks em ~/.claude/settings.json (sem segredo: o
    # token fica em ~/.local/share/ai-memory/auth-token).
    run([str(SCRIPT_DIR / "ai-memory-install-cli.sh")], dry_run)
    common = ["--server-url", values["AI_MEMORY_URL"], "--auth-token", values["AI_MEMORY_TOKEN"], "--apply"]
    run([str(AI_MEMORY_BIN), "install-mcp", "--client", "claude-code", *common], dry_run, quiet=True)
    run([str(AI_MEMORY_BIN), "install-hooks", "--agent", "claude-code", *common, *HOOK_CAPTURE_FLAGS], dry_run, quiet=True)
    if not dry_run:
        print("MCP e hooks ai-memory configurados (reinicie o Claude Code).")


def opencode_entry(spec: dict, values: dict) -> dict:
    if "url" in spec:
        return {
            "type": "remote",
            "url": spec["url"](values),
            "enabled": True,
            "headers": spec["headers"](values),
        }
    entry = {"type": "local", "command": spec["command"], "enabled": True}
    if spec["env"]:
        entry["environment"] = {var: values[var] for var in spec["env"]}
    return entry


def load_jsonc(path: Path) -> dict:
    raw = path.read_text()
    raw = re.sub(r"^\s*//.*$", "", raw, flags=re.M)  # comentarios de linha inteira
    raw = re.sub(r",(\s*[}\]])", r"\1", raw)  # virgulas finais
    return json.loads(raw)


def setup_opencode(all_values: dict, dry_run: bool) -> None:
    cfg = {"$schema": "https://opencode.ai/config.json"}
    if OPENCODE_CONFIG.exists():
        cfg.update(load_jsonc(OPENCODE_CONFIG))
    mcp = cfg.setdefault("mcp", {})
    for name, spec in SERVERS.items():
        mcp[name] = opencode_entry(spec, all_values[name])
    mcp.pop("inkdrop-mcp-server", None)  # nome antigo

    if dry_run:
        print(f"[dry-run] gravaria {OPENCODE_CONFIG} com MCPs: {', '.join(mcp)}")
    else:
        OPENCODE_CONFIG.parent.mkdir(parents=True, exist_ok=True)
        OPENCODE_CONFIG.write_text(json.dumps(cfg, indent=2) + "\n")
        OPENCODE_CONFIG.chmod(0o600)  # contem o token do ai-memory
        print(f"MCPs configurados no opencode ({OPENCODE_CONFIG}).")
    setup_opencode_ai_memory_hooks(all_values["ai-memory"], dry_run)


def setup_opencode_ai_memory_hooks(values: dict, dry_run: bool) -> None:
    # O MCP so da ferramentas sob demanda; a captura automatica de sessoes vem do
    # plugin em ~/.config/opencode/plugins/ (sem ele nada e gravado sozinho).
    run([str(SCRIPT_DIR / "ai-memory-install-cli.sh")], dry_run)
    run(
        [str(AI_MEMORY_BIN), "install-hooks", "--agent", "open-code",
         "--server-url", values["AI_MEMORY_URL"], "--auth-token", values["AI_MEMORY_TOKEN"], "--apply",
         *HOOK_CAPTURE_FLAGS],
        dry_run, quiet=True,
    )
    if not dry_run:
        print("Hooks ai-memory instalados no opencode (reinicie o opencode).")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--client", choices=["claude", "opencode", "all"], default="all")
    parser.add_argument("--dry-run", action="store_true", help="mostra o que faria, sem alterar nada")
    args = parser.parse_args()

    all_values = {name: load_values(name, spec) for name, spec in SERVERS.items()}
    if args.client in ("claude", "all"):
        setup_claude(all_values, args.dry_run)
    if args.client in ("opencode", "all"):
        setup_opencode(all_values, args.dry_run)


if __name__ == "__main__":
    main()
