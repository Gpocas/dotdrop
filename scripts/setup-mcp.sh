#!/usr/bin/env bash
# Wrapper: a logica vive em setup-mcp.py (veja --help).
exec python3 "$(dirname "${BASH_SOURCE[0]}")/setup-mcp.py" "$@"
