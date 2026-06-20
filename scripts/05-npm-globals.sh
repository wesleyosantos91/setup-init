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

# Instala apenas os pacotes ausentes (pula os já presentes no Node atual).
# Use SETUP_UPDATE=1 para reinstalar/atualizar todos, mesmo os existentes.
to_install=()
for pkg in "${PKGS[@]}"; do
  if [[ "${SETUP_UPDATE:-0}" != "1" ]] && npm ls -g --depth=0 "$pkg" >/dev/null 2>&1; then
    ok "$pkg já instalado"
  else
    to_install+=("$pkg")
  fi
done

if [[ ${#to_install[@]} -gt 0 ]]; then
  log "Instalando: ${to_install[*]}"
  npm install -g "${to_install[@]}"
  ok "Pacotes npm globais instalados"
else
  ok "Todos os pacotes npm globais já presentes — nada a instalar"
fi
