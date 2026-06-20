#!/usr/bin/env bash
# Ferramentas extras de produtividade.
#   Git+terminal : git-delta, fzf, zoxide, bat, fd
#   Dev workflow : direnv, lazygit, lazydocker, pre-commit, gitleaks
#   Sistema/diag : btop, tmux, shellcheck, tldr (tealdeer), yq
#
# Estratégia por origem:
#   - EPEL/dnf  -> pacotes disponíveis no repo (RHEL 9/10)
#   - binário   -> releases do GitHub para ~/.local/bin (lazygit, lazydocker, gitleaks, yq)
#   - cargo     -> tealdeer (tldr)  [usa o Rust do script 11]
#   - pip       -> pre-commit       [usa o Python do pyenv, script 04]
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

section "Ferramentas extras"

mkdir -p "$HOME/.local/bin"

# --- EPEL (necessário para várias dessas ferramentas) ---
RHEL_VER="$(. /etc/os-release; echo "${VERSION_ID%%.*}")"
if ! sudo dnf repolist 2>/dev/null | grep -qi epel; then
  log "Habilitando EPEL"
  sudo dnf -y install "https://dl.fedoraproject.org/pub/epel/epel-release-latest-${RHEL_VER}.noarch.rpm" || \
    warn "Falha ao habilitar EPEL automaticamente — alguns pacotes podem faltar"
fi

# --- CRB (CodeReady Linux Builder) — exigido por muitos pacotes EPEL no RHEL 10+ ---
# O próprio epel-release avisa: "It is recommended that you run /usr/bin/crb enable"
if [[ "$RHEL_VER" -ge 10 ]]; then
  log "Habilitando CRB (requerido por pacotes EPEL)"
  sudo /usr/bin/crb enable 2>/dev/null || \
    sudo dnf config-manager --enable crb 2>/dev/null || \
    warn "CRB não pôde ser habilitado — zoxide/direnv podem não estar disponíveis"
fi

# --- Pacotes via dnf/EPEL ---
# Nomes de pacote (que diferem do comando):
#   fd      -> fd-find       | bat -> bat       | delta -> git-delta
#   shellcheck -> ShellCheck
log "Instalando pacotes via dnf/EPEL"
sudo dnf -y install \
  git-delta fzf zoxide bat fd-find \
  direnv \
  btop tmux ShellCheck yq \
  2>/dev/null || warn "Alguns pacotes dnf falharam (ver acima); seguindo com binários"

# 'fd' às vezes vem como 'fdfind' — cria atalho se preciso
if ! have fd && have fdfind; then
  ln -sf "$(command -v fdfind)" "$HOME/.local/bin/fd"
fi
# 'bat' às vezes vem como 'batcat'
if ! have bat && have batcat; then
  ln -sf "$(command -v batcat)" "$HOME/.local/bin/bat"
fi

# --- Binários do GitHub (arquitetura detectada) ---
ARCH="$(uname -m)"   # x86_64 / aarch64

# Baixa o asset de release cujo nome casa com um padrão; extrai o binário.
install_gh_bin() {
  local repo="$1" pattern="$2" binname="$3"
  if have "$binname"; then ok "$binname já instalado"; return; fi
  log "Instalando $binname (github:$repo)"
  local url tmp
  url="$(curl -fsSL "https://api.github.com/repos/$repo/releases/latest" \
        | grep -oE "https://[^\"]+${pattern}[^\"]*" | head -1)"
  if [[ -z "$url" ]]; then warn "Release de $binname não encontrada — pule/instale manual"; return; fi
  tmp="$(mktemp -d)"
  curl -fsSL "$url" -o "$tmp/pkg"
  case "$url" in
    *.tar.gz|*.tgz) tar -xzf "$tmp/pkg" -C "$tmp" ;;
    *.zip)          unzip -q "$tmp/pkg" -d "$tmp" ;;
    *)              cp "$tmp/pkg" "$tmp/$binname"; chmod +x "$tmp/$binname" ;;
  esac
  local found
  found="$(find "$tmp" -type f -name "$binname" | head -1)"
  if [[ -n "$found" ]]; then
    install -m 755 "$found" "$HOME/.local/bin/$binname"
    ok "$binname -> ~/.local/bin"
  else
    warn "Binário $binname não localizado no pacote baixado"
  fi
  rm -rf "$tmp"
}

# lazygit / lazydocker / gitleaks -> tarballs Linux x86_64
LZ_ARCH="$ARCH"; [[ "$ARCH" == "aarch64" ]] && LZ_ARCH="arm64"
install_gh_bin "jesseduffield/lazygit"    "Linux_${ARCH}.tar.gz"     "lazygit"
install_gh_bin "jesseduffield/lazydocker" "Linux_${ARCH}.tar.gz"     "lazydocker"
install_gh_bin "gitleaks/gitleaks"        "linux_${LZ_ARCH}.tar.gz"  "gitleaks"
# yq (mikefarah) — só se não veio do EPEL
if ! have yq; then
  YQ_ARCH="amd64"; [[ "$ARCH" == "aarch64" ]] && YQ_ARCH="arm64"
  install_gh_bin "mikefarah/yq" "yq_linux_${YQ_ARCH}\b" "yq"
fi

# --- Fallbacks para pacotes ausentes no EPEL 10 ---
# git-delta, zoxide e direnv ainda não foram portados para o EPEL 10 (mesmo
# com CRB habilitado). Quando o dnf não os instala, usamos binário/cargo.

# git-delta (comando: delta) — binário GitHub
if ! have delta; then
  DELTA_TARGET="x86_64-unknown-linux-musl"
  [[ "$ARCH" == "aarch64" ]] && DELTA_TARGET="aarch64-unknown-linux-gnu"
  install_gh_bin "dandavison/delta" "${DELTA_TARGET}.tar.gz" "delta"
fi

# zoxide — via cargo (Rust dos scripts 03/04); fallback p/ script oficial
if ! have zoxide; then
  # shellcheck source=/dev/null
  [[ -s "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"
  if have cargo; then
    log "Instalando zoxide via cargo"
    cargo install zoxide --locked || warn "Falha ao instalar zoxide via cargo"
  else
    log "cargo indisponível — instalando zoxide via script oficial"
    curl -fsSL https://raw.githubusercontent.com/ajeetdsoudy/zoxide/main/install.sh \
      | bash -s -- --bin-dir "$HOME/.local/bin" 2>/dev/null \
      || warn "Falha ao instalar zoxide (instale manualmente)"
  fi
fi

# direnv — binário GitHub (asset é o binário direto, não tarball)
if ! have direnv; then
  DIR_ARCH="amd64"; [[ "$ARCH" == "aarch64" ]] && DIR_ARCH="arm64"
  install_gh_bin "direnv/direnv" "direnv.linux-${DIR_ARCH}" "direnv"
fi

# --- tldr via tealdeer (cargo) ---
if have tldr; then
  ok "tldr já instalado"
elif have cargo; then
  log "Instalando tealdeer (tldr) via cargo"
  cargo install tealdeer || warn "Falha ao instalar tealdeer"
else
  warn "cargo indisponível — pulei tldr (rode o script 11-rust antes)"
fi

# --- pre-commit via pip (Python do pyenv) ---
if have pre-commit; then
  ok "pre-commit já instalado"
elif have pip; then
  log "Instalando pre-commit via pip"
  pip install --upgrade pre-commit || warn "Falha ao instalar pre-commit"
else
  warn "pip indisponível — pulei pre-commit (rode o script 04-sdks antes)"
fi

ok "Ferramentas extras processadas"
