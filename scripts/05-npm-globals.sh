#!/usr/bin/env bash
# Pacotes npm globais (instalados no Node default do nvm).
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

section "Pacotes npm globais"

export NVM_DIR="$HOME/.nvm"
if [[ -s "$NVM_DIR/nvm.sh" ]]; then
  set +u; source "$NVM_DIR/nvm.sh"; set -u
  nvm use default >/dev/null 2>&1 || nvm use 22 >/dev/null 2>&1
else
  warn "nvm não encontrado — usando npm do PATH"
fi

if ! have npm; then
  err "npm não disponível. Rode 03/04 antes."; exit 1
fi

PKGS=(
  @devcontainers/cli
  @fission-ai/openspec
  @github/copilot
  @google/gemini-cli
  @openai/codex
  corepack
  repomix
)

log "Instalando: ${PKGS[*]}"
npm install -g "${PKGS[@]}"

ok "Pacotes npm globais instalados"
