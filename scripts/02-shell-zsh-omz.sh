#!/usr/bin/env bash
# Zsh + Oh My Zsh + Powerlevel10k + plugins, e define zsh como shell padrão.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

section "Zsh + Oh My Zsh + Powerlevel10k"

# Atualiza um repo git se já existe; senão clona (validar -> atualizar -> sub-ação)
clone_or_update() {
  local url="$1" dest="$2"
  if [[ -d "$dest/.git" ]]; then
    log "Atualizando $(basename "$dest")"
    git -C "$dest" pull --ff-only 2>/dev/null || warn "não atualizou $(basename "$dest")"
  else
    log "Instalando $(basename "$dest")"
    git clone --depth=1 "$url" "$dest"
  fi
}

# --- Oh My Zsh ---
if [[ -d "$HOME/.oh-my-zsh" ]]; then
  log "Oh My Zsh presente — atualizando"
  git -C "$HOME/.oh-my-zsh" pull --ff-only 2>/dev/null || warn "não atualizou o oh-my-zsh"
else
  log "Instalando Oh My Zsh"
  RUNZSH=no KEEP_ZSHRC=yes sh -c \
    "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

# --- Tema Powerlevel10k ---
clone_or_update "https://github.com/romkatv/powerlevel10k.git" "$ZSH_CUSTOM/themes/powerlevel10k"

# --- Plugins ---
declare -A PLUGINS=(
  [zsh-autosuggestions]="https://github.com/zsh-users/zsh-autosuggestions"
  [zsh-syntax-highlighting]="https://github.com/zsh-users/zsh-syntax-highlighting"
)
for name in "${!PLUGINS[@]}"; do
  clone_or_update "${PLUGINS[$name]}" "$ZSH_CUSTOM/plugins/$name"
done

# --- Define zsh como shell padrão ---
if [[ "$SHELL" != *zsh ]]; then
  log "Definindo zsh como shell padrão"
  sudo chsh -s "$(command -v zsh)" "$USER" || warn "Não consegui mudar o shell automaticamente; rode: chsh -s \$(which zsh)"
else
  ok "zsh já é o shell padrão"
fi

ok "Ambiente de shell pronto"
