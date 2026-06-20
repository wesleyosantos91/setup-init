#!/usr/bin/env bash
# Restaura os arquivos de configuração (dotfiles) exatamente como estavam.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

section "Dotfiles (shell, git, p10k, ssh, gh)"

# Mapa: arquivo no repo  ->  destino no $HOME
install_file() {
  local src="$1" dest="$2" mode="${3:-644}"
  [[ -f "$src" ]] || { warn "fonte ausente: $src"; return; }
  mkdir -p "$(dirname "$dest")"
  backup_if_exists "$dest"
  install -m "$mode" "$src" "$dest"
  ok "$dest"
}

# --- Shell ---
install_file "$DOTFILES_DIR/zshrc"          "$HOME/.zshrc"
install_file "$DOTFILES_DIR/bashrc"         "$HOME/.bashrc"
install_file "$DOTFILES_DIR/bash_profile"   "$HOME/.bash_profile"
install_file "$DOTFILES_DIR/profile"        "$HOME/.profile"
install_file "$DOTFILES_DIR/p10k.zsh"       "$HOME/.p10k.zsh"

# --- Git ---
install_file "$DOTFILES_DIR/gitconfig"          "$HOME/.gitconfig"
install_file "$DOTFILES_DIR/gitignore_global"   "$HOME/.gitignore_global"
install_file "$DOTFILES_DIR/gitconfig-itau"     "$HOME/.gitconfig-itau"
install_file "$DOTFILES_DIR/git/allowed_signers" "$HOME/.config/git/allowed_signers"

# --- GitHub CLI ---
install_file "$DOTFILES_DIR/gh/config.yml"  "$HOME/.config/gh/config.yml"
install_file "$DOTFILES_DIR/gh/hosts.yml"   "$HOME/.config/gh/hosts.yml"

# --- SSH (config + chaves) ---
mkdir -p "$HOME/.ssh"; chmod 700 "$HOME/.ssh"
install_file "$DOTFILES_DIR/ssh/config" "$HOME/.ssh/config" 600

if [[ -d "$SECRETS_DIR" ]]; then
  log "Restaurando chaves SSH (secrets/)"
  for k in id_rsa_git_signing id_rsa_github; do
    [[ -f "$SECRETS_DIR/$k" ]]     && install -m 600 "$SECRETS_DIR/$k"     "$HOME/.ssh/$k"     && ok ".ssh/$k"
    [[ -f "$SECRETS_DIR/$k.pub" ]] && install -m 644 "$SECRETS_DIR/$k.pub" "$HOME/.ssh/$k.pub" && ok ".ssh/$k.pub"
  done
  [[ -f "$SECRETS_DIR/known_hosts" ]] && install -m 644 "$SECRETS_DIR/known_hosts" "$HOME/.ssh/known_hosts"
else
  warn "Pasta secrets/ não encontrada — chaves SSH não restauradas"
fi

ok "Dotfiles restaurados"
