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
ZSH_BIN="$(command -v zsh 2>/dev/null || true)"
if [[ -z "$ZSH_BIN" ]]; then
  warn "zsh não encontrado — instale-o via 00-system-packages antes de rodar este script"
elif [[ "$SHELL" == *zsh ]]; then
  ok "zsh já é o shell padrão"
else
  log "Definindo zsh como shell padrão"
  # chsh exige que o shell esteja listado em /etc/shells
  grep -qxF "$ZSH_BIN" /etc/shells || echo "$ZSH_BIN" | sudo tee -a /etc/shells >/dev/null
  sudo chsh -s "$ZSH_BIN" "$USER" \
    || sudo usermod -s "$ZSH_BIN" "$USER" \
    || warn "Não consegui mudar o shell; rode manualmente: chsh -s $ZSH_BIN"
fi

ok "Ambiente de shell pronto"
