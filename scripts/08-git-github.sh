#!/usr/bin/env bash
# Autenticação do GitHub CLI e verificação da configuração git.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

section "GitHub CLI (autenticação)"

if ! have gh; then
  err "gh não instalado — rode 00-system-packages.sh antes"; exit 1
fi

if gh auth status >/dev/null 2>&1; then
  ok "gh já autenticado"
else
  warn "É necessário autenticar no GitHub (passo interativo)."
  echo "Conta original: wesleyosantos91 | protocolo git: ssh"
  echo "Escopos: admin:public_key, admin:ssh_signing_key, gist, read:org, repo"
  echo
  # '|| true': sob set -e, o read retorna não-zero ao receber EOF (execução
  # não-interativa) e abortaria o script antes de tratar o caso "não".
  resp=""
  read -r -p "Autenticar agora com 'gh auth login'? [s/N] " resp || true
  if [[ "$resp" =~ ^[sS]$ ]]; then
    # admin:ssh_signing_key é necessário p/ cadastrar a chave de ASSINATURA
    # (gh ssh-key add --type signing); admin:public_key cobre só a de auth.
    gh auth login -h github.com -p ssh -s admin:public_key,admin:ssh_signing_key,gist,read:org,repo
  else
    warn "Pule por enquanto. Depois rode: gh auth login -h github.com -p ssh"
  fi
fi

# Garante que a chave SSH de assinatura esteja registrada no agent
if have ssh-add; then
  eval "$(ssh-agent -s)" >/dev/null 2>&1 || true
  ssh-add "$HOME/.ssh/id_rsa_github" 2>/dev/null || true
fi

# --- Registrar as chaves públicas na conta do GitHub (semi-automático) ---
# Só funciona se o gh estiver autenticado e o token tiver escopo admin:public_key.
if gh auth status >/dev/null 2>&1; then
  host="$(hostname -s 2>/dev/null || echo setup)"

  # Lista títulos já cadastrados para evitar duplicar
  existing_auth="$(gh ssh-key list 2>/dev/null || true)"

  reg_key() {
    local pub="$1" type="$2" title="$3"
    [[ -f "$pub" ]] || { warn "chave ausente: $pub"; return; }
    if echo "$existing_auth" | grep -q "$title"; then
      ok "chave '$title' ($type) já cadastrada no GitHub"
    else
      log "Cadastrando chave '$title' ($type) no GitHub"
      gh ssh-key add "$pub" --title "$title" --type "$type" \
        && ok "chave $type cadastrada" \
        || warn "não consegui cadastrar a chave $type (auth precisa de admin:public_key; signing precisa de admin:ssh_signing_key — rode: gh auth refresh -h github.com -s admin:ssh_signing_key)"
    fi
  }

  # Chave de autenticação e chave de assinatura
  reg_key "$HOME/.ssh/id_rsa_github.pub"      authentication "${host}-auth"
  reg_key "$HOME/.ssh/id_rsa_git_signing.pub" signing        "${host}-signing"
else
  warn "gh não autenticado — pulei o cadastro automático das chaves SSH."
  warn "Após autenticar, rode novamente este script (08) para registrá-las."
fi

echo
log "Verificação rápida da config git:"
git config --global user.name  || true
git config --global user.email || true
git config --global commit.gpgsign || true

ok "Git/GitHub configurados"
