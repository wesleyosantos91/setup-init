#!/usr/bin/env bash
# Instala os gerenciadores de versão: SDKMAN, nvm, pyenv, goenv.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

section "Gerenciadores de versão (SDKMAN, nvm, pyenv, goenv, rustup)"

# --- SDKMAN (Java / Maven / Gradle) ---
if [[ -d "$HOME/.sdkman" ]]; then
  log "SDKMAN presente — atualizando (selfupdate)"
  set +u; source "$HOME/.sdkman/bin/sdkman-init.sh"; set -u
  sdk selfupdate force >/dev/null 2>&1 || warn "não atualizou o SDKMAN"
else
  log "Instalando SDKMAN"
  curl -s "https://get.sdkman.io?rcupdate=false" | bash
fi

# --- nvm (Node) ---
if [[ -d "$HOME/.nvm/.git" ]]; then
  log "nvm presente — atualizando para a última tag"
  git -C "$HOME/.nvm" fetch --tags --quiet || true
  latest="$(git -C "$HOME/.nvm" describe --abbrev=0 --tags --match 'v[0-9]*' 2>/dev/null)"
  [[ -n "${latest:-}" ]] && git -C "$HOME/.nvm" checkout -q "$latest" || warn "não atualizou o nvm"
elif [[ -d "$HOME/.nvm" ]]; then
  ok "nvm presente (instalação sem git) — mantido"
else
  log "Instalando nvm"
  PROFILE=/dev/null bash -c \
    'curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash'
fi

# --- pyenv (Python) ---
if [[ -d "$HOME/.pyenv/.git" ]]; then
  log "pyenv presente — atualizando"
  git -C "$HOME/.pyenv" pull --ff-only 2>/dev/null || warn "não atualizou o pyenv"
elif [[ -d "$HOME/.pyenv" ]]; then
  ok "pyenv presente — mantido"
else
  log "Instalando pyenv"
  curl -fsSL https://pyenv.run | bash
fi

# --- goenv (Go) ---
if [[ -d "$HOME/.goenv/.git" ]]; then
  log "goenv presente — atualizando"
  git -C "$HOME/.goenv" pull --ff-only 2>/dev/null || warn "não atualizou o goenv"
elif [[ -d "$HOME/.goenv" ]]; then
  ok "goenv presente — mantido"
else
  log "Instalando goenv"
  git clone --depth=1 https://github.com/go-nv/goenv.git "$HOME/.goenv"
fi

# --- rustup (Rust) ---
if [[ -d "$HOME/.rustup" ]] && have rustc; then
  log "rustup presente — atualizando toolchain stable"
  # shellcheck source=/dev/null
  [[ -s "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"
  rustup update stable 2>/dev/null || warn "não atualizou o rustup"
else
  log "Instalando rustup"
  # -y: não interativo | --no-modify-path: PATH gerenciado pelos dotfiles
  curl --proto '=https' --tlsv1.2 -fsSL https://sh.rustup.rs \
    | sh -s -- -y --default-toolchain stable --profile default --no-modify-path
fi

ok "Gerenciadores de versão instalados (os dotfiles já cuidam do PATH/init)"
