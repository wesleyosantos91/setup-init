#!/usr/bin/env bash
# Habilita o serviço do Docker e adiciona o usuário ao grupo docker.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

section "Docker (serviço + grupo)"

if ! have docker; then
  err "docker não instalado — rode 00-system-packages.sh antes"; exit 1
fi

log "Habilitando e iniciando o serviço docker"
sudo systemctl enable --now docker

# Grupo docker (para usar sem sudo)
if getent group docker >/dev/null; then
  if id -nG "$USER" | tr ' ' '\n' | grep -qx docker; then
    ok "Usuário já está no grupo docker"
  else
    log "Adicionando $USER ao grupo docker"
    sudo usermod -aG docker "$USER"
    warn "Faça logout/login (ou 'newgrp docker') para o grupo ter efeito"
  fi
fi

ok "Docker configurado"
