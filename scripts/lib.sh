#!/usr/bin/env bash
# Funções auxiliares compartilhadas entre os scripts de setup.

# Diretório raiz do projeto (um nível acima de scripts/)
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DOTFILES_DIR="$ROOT_DIR/dotfiles"
SECRETS_DIR="$ROOT_DIR/secrets"

# Cores
C_RESET='\033[0m'; C_GREEN='\033[1;32m'; C_BLUE='\033[1;34m'; C_YELLOW='\033[1;33m'; C_RED='\033[1;31m'

log()   { echo -e "${C_BLUE}==>${C_RESET} $*"; }
ok()    { echo -e "${C_GREEN} ✓${C_RESET} $*"; }
warn()  { echo -e "${C_YELLOW} !${C_RESET} $*"; }
err()   { echo -e "${C_RED} ✗${C_RESET} $*" >&2; }
section(){ echo -e "\n${C_GREEN}########## $* ##########${C_RESET}"; }

have() { command -v "$1" >/dev/null 2>&1; }

# Faz backup de um arquivo existente antes de sobrescrever
backup_if_exists() {
  local f="$1"
  if [[ -e "$f" && ! -L "$f" ]]; then
    cp -a "$f" "${f}.bak.$(date +%Y%m%d%H%M%S)"
    warn "backup criado: ${f}.bak.*"
  fi
}
