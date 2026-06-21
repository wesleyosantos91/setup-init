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
  warn "Pasta secrets/ não encontrada — chaves SSH serão geradas se ausentes"
fi

# Se alguma chave continuar ausente (sem backup em secrets/), gera uma nova
# automaticamente (ed25519). A pública é cadastrada no GitHub pela etapa 08
# (requer 'gh' autenticado com escopo admin:public_key).
gen_ssh_key() {
  local path="$1" comment="$2"
  [[ -f "$path" ]] && return 0
  log "Gerando chave SSH ausente: $(basename "$path")"
  ssh-keygen -t ed25519 -C "$comment" -f "$path" -N "" -q
  chmod 600 "$path"; chmod 644 "$path.pub"
  ok "gerada $(basename "$path") — a etapa 08 cadastra a .pub no GitHub"
}
host_tag="$(whoami)@$(hostname -s 2>/dev/null || echo host)"
gen_ssh_key "$HOME/.ssh/id_rsa_github"      "$host_tag github auth"
gen_ssh_key "$HOME/.ssh/id_rsa_git_signing" "$host_tag git signing"

# Garante que a chave de assinatura esteja no allowed_signers (p/ verificação
# local de commits assinados; necessário quando a chave foi gerada agora).
ALLOWED="$HOME/.config/git/allowed_signers"
SIGN_PUB="$HOME/.ssh/id_rsa_git_signing.pub"
if [[ -f "$SIGN_PUB" ]]; then
  mkdir -p "$(dirname "$ALLOWED")"
  sign_key="$(cat "$SIGN_PUB")"
  if ! grep -qF "$sign_key" "$ALLOWED" 2>/dev/null; then
    echo "wesleyosantos91@gmail.com $sign_key" >> "$ALLOWED"
    ok "chave de assinatura adicionada ao allowed_signers"
  fi
fi

ok "Dotfiles restaurados"
