#!/usr/bin/env bash
# Pacotes de sistema via dnf + repositórios necessários.
# Compatível com RHEL 9 (dnf4) e RHEL 10 (dnf5).
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

section "Pacotes de sistema (dnf)"

# Versão major do RHEL (9, 10, ...)
RHEL_VER="$(. /etc/os-release; echo "${VERSION_ID%%.*}")"
log "Detectado RHEL major = ${RHEL_VER}"

# Baixa um .repo direto para /etc/yum.repos.d (funciona em dnf4 e dnf5,
# evitando as diferenças do 'config-manager' entre as versões).
add_repo() {
  local url="$1" dest="/etc/yum.repos.d/$2"
  if [[ -f "$dest" ]]; then ok "repo $(basename "$dest") já existe"; return; fi
  log "Adicionando repo: $(basename "$dest")"
  sudo curl -fsSL "$url" -o "$dest"
}

# --- CRB (CodeReady Linux Builder) — exigido pelos pacotes -devel no RHEL 10 ---
# Tenta habilitar via dnf config-manager (dnf5/dnf4) ou subscription-manager.
if [[ "$RHEL_VER" -ge 10 ]]; then
  log "Habilitando repositório CRB (CodeReady Linux Builder)"
  if sudo dnf config-manager --enable crb 2>/dev/null; then
    ok "CRB habilitado via dnf config-manager"
  elif sudo subscription-manager repos \
         --enable "codeready-builder-for-rhel-${RHEL_VER}-$(arch)-rpms" 2>/dev/null; then
    ok "CRB habilitado via subscription-manager"
  else
    warn "CRB não pôde ser habilitado — pacotes *-devel podem não estar disponíveis"
  fi
fi

# --- Repositório Docker CE ---
add_repo "https://download.docker.com/linux/rhel/docker-ce.repo" "docker-ce.repo"
# A Docker pode ainda não publicar o caminho para o RHEL mais novo ($releasever).
# Se o major atual não tiver pacotes, fixamos releasever=9 (binário compatível).
if ! sudo dnf -q --disablerepo='*' --enablerepo='docker-ce-stable' \
       list available docker-ce >/dev/null 2>&1; then
  if [[ "$RHEL_VER" != "9" ]]; then
    warn "Docker CE sem pacotes para RHEL ${RHEL_VER}; fixando releasever=9 no repo"
    sudo sed -i 's|/rhel/\$releasever/|/rhel/9/|g' /etc/yum.repos.d/docker-ce.repo
  fi
fi

# --- Repositório GitHub CLI (gh) ---
add_repo "https://cli.github.com/packages/rpm/gh-cli.repo" "gh-cli.repo"

# No RHEL 10 (dnf5) usamos --skip-unavailable para não abortar caso algum
# pacote ainda não exista no repositório ativo (ex.: sistema sem assinatura).
DNF_EXTRA_FLAGS=""
if [[ "$RHEL_VER" -ge 10 ]]; then
  DNF_EXTRA_FLAGS="--skip-unavailable"
fi

# --- Pacotes base de desenvolvimento ---
log "Instalando ferramentas base"
# shellcheck disable=SC2086
sudo dnf -y $DNF_EXTRA_FLAGS install \
  git gh jq make automake gcc gcc-c++ cmake \
  curl wget tree vim-enhanced zsh \
  zlib-devel bzip2 bzip2-devel readline-devel sqlite sqlite-devel \
  openssl-devel xz xz-devel libffi-devel tk-devel \
  patch findutils which unzip zip tar gzip

# Dependências acima de readline/sqlite/openssl/etc são necessárias para
# compilar Python (pyenv) e Go (goenv) a partir do fonte.

# --- Docker CE ---
log "Instalando Docker CE"
# shellcheck disable=SC2086
sudo dnf -y $DNF_EXTRA_FLAGS install docker-ce docker-ce-cli containerd.io \
  docker-buildx-plugin docker-compose-plugin docker-ce-rootless-extras

ok "Pacotes de sistema instalados"
