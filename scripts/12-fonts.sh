#!/usr/bin/env bash
# Restaura as fontes do usuário (Nerd Font MesloLGS NF, usada pelo Powerlevel10k).
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

section "Fontes (Nerd Font / Powerlevel10k)"

SRC="$DOTFILES_DIR/fonts"
DEST="$HOME/.local/share/fonts"

if [[ -d "$SRC" ]]; then
  log "Instalando fontes em $DEST"
  mkdir -p "$DEST"
  cp -a "$SRC/." "$DEST/"
  if have fc-cache; then
    fc-cache -f "$DEST" >/dev/null 2>&1 || true
  fi
  ok "Fontes restauradas (MesloLGS NF e demais)"
else
  warn "Pasta dotfiles/fonts ausente — nada a restaurar"
fi
