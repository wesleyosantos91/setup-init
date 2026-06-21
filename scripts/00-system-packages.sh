#!/usr/bin/env bash
# Pacotes de sistema via dnf + repositórios necessários.
# Compatível com RHEL 9 (dnf4) e RHEL 10 (dnf5).
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

section "Pacotes de sistema (dnf)"

# Versão major do RHEL (9, 10, ...)
RHEL_VER="$(. /etc/os-release; echo "${VERSION_ID%%.*}")"
log "Detectado RHEL major = ${RHEL_VER}"

# zlib (headers p/ compilar Python no pyenv):
#   RHEL 9  -> zlib-devel
#   RHEL 10 -> zlib-devel foi substituído por zlib-ng-compat-devel
if [[ "$RHEL_VER" -ge 10 ]]; then
  ZLIB_PKG="zlib-ng-compat-devel"
else
  ZLIB_PKG="zlib-devel"
fi

# Baixa um .repo direto para /etc/yum.repos.d (funciona em dnf4 e dnf5,
# evitando as diferenças do 'config-manager' entre as versões).
add_repo() {
  local url="$1" dest="/etc/yum.repos.d/$2"
  if [[ -f "$dest" ]]; then ok "repo $(basename "$dest") já existe"; return; fi
  log "Adicionando repo: $(basename "$dest")"
  sudo curl -fsSL "$url" -o "$dest"
}

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

# --- Pacotes base de desenvolvimento ---
log "Instalando ferramentas base"
sudo dnf -y install \
  git gh jq make automake gcc gcc-c++ cmake \
  curl wget tree vim-enhanced zsh \
  "$ZLIB_PKG" bzip2 bzip2-devel readline-devel sqlite sqlite-devel \
  openssl-devel xz xz-devel libffi-devel tk-devel \
  patch findutils which unzip zip tar gzip

# Dependências acima de readline/sqlite/openssl/etc são necessárias para
# compilar Python (pyenv) e Go (goenv) a partir do fonte.

# --- Docker CE ---
log "Instalando Docker CE"
sudo dnf -y install docker-ce docker-ce-cli containerd.io \
  docker-buildx-plugin docker-compose-plugin docker-ce-rootless-extras

ok "Pacotes de sistema instalados"
