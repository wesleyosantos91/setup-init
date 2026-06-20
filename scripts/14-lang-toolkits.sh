#!/usr/bin/env bash
# Toolkits de produtividade/validação por linguagem.
#   JVM    : mvnd, springboot, jbang            (SDKMAN)
#   Go     : golangci-lint, goimports, dlv,      (go install -> ~/go/bin)
#            govulncheck, air, mockgen
#   Python : uv, pipx, ruff, mypy, pytest        (uv installer + pipx)
#   Node   : pnpm, yarn (corepack) + tsc,        (corepack + npm -g)
#            prettier, eslint
#   Rust   : cargo-watch, cargo-nextest,         (cargo install + rustup component)
#            cargo-audit, cargo-edit, cargo-update,
#            sccache, rust-analyzer
# Obs: sem 'set -u' — SDKMAN/pyenv/goenv/nvm não são compatíveis com nounset.
set -eo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

# ===========================================================================
section "JVM toolkit (SDKMAN)"
# ===========================================================================
export SDKMAN_DIR="$HOME/.sdkman"
if [[ -s "$SDKMAN_DIR/bin/sdkman-init.sh" ]]; then
  # SDKMAN não é compatível com 'set -u'; desliga durante todo o uso dele.
  set +u
  source "$SDKMAN_DIR/bin/sdkman-init.sh"
  for c in mvnd springboot jbang; do
    log "sdk install $c"
    echo n | sdk install "$c" >/dev/null 2>&1 || true
    if [[ -d "$SDKMAN_DIR/candidates/$c" ]]; then ok "$c instalado"; else warn "falha em $c"; fi
  done
  set -u
  ok "JVM toolkit pronto"
else
  warn "SDKMAN ausente — rode 03-version-managers antes"
fi

# ===========================================================================
section "Go toolkit (go install)"
# ===========================================================================
export GOENV_ROOT="$HOME/.goenv"; export PATH="$GOENV_ROOT/bin:$PATH"
eval "$(goenv init - 2>/dev/null)" || true
export GOPATH="$HOME/go"; export PATH="$GOPATH/bin:$PATH"
if have go; then
  declare -a GO_PKGS=(
    "github.com/golangci/golangci-lint/cmd/golangci-lint@latest"
    "golang.org/x/tools/cmd/goimports@latest"
    "github.com/go-delve/delve/cmd/dlv@latest"
    "golang.org/x/vuln/cmd/govulncheck@latest"
    "github.com/air-verse/air@latest"
    "go.uber.org/mock/mockgen@latest"
  )
  for p in "${GO_PKGS[@]}"; do
    log "go install $p"
    go install "$p" || warn "falha em $p"
  done
  ok "Go toolkit pronto (binários em ~/go/bin)"
else
  warn "go ausente — rode 03/04 antes"
fi

# ===========================================================================
section "Python toolkit (uv + pipx)"
# ===========================================================================
export PYENV_ROOT="$HOME/.pyenv"; export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init - 2>/dev/null)" || true
export PATH="$HOME/.local/bin:$PATH"

# uv (instalador oficial)
if have uv; then
  ok "uv já instalado"
else
  log "Instalando uv"
  curl -LsSf https://astral.sh/uv/install.sh | sh || warn "falha ao instalar uv"
fi

# pipx
if have pipx; then
  ok "pipx já instalado"
elif have pip; then
  log "Instalando pipx"
  pip install --user pipx || warn "falha ao instalar pipx"
  python -m pipx ensurepath >/dev/null 2>&1 || true
fi

# CLIs Python isoladas via pipx
if have pipx; then
  for tool in ruff mypy pytest; do
    log "pipx install $tool"
    pipx install "$tool" || warn "falha em $tool"
  done
  ok "Python toolkit pronto"
else
  warn "pipx indisponível — instale ruff/mypy/pytest manualmente"
fi

# ===========================================================================
section "Node toolkit (corepack + globais)"
# ===========================================================================
export NVM_DIR="$HOME/.nvm"
if [[ -s "$NVM_DIR/nvm.sh" ]]; then set +u; source "$NVM_DIR/nvm.sh"; set -u; nvm use default >/dev/null 2>&1 || true; fi
if have corepack; then
  log "Habilitando pnpm e yarn via corepack"
  corepack enable || true
  corepack prepare pnpm@latest --activate || warn "falha pnpm"
  corepack prepare yarn@stable --activate || warn "falha yarn"
fi
if have npm; then
  log "Instalando typescript, prettier, eslint (globais)"
  npm install -g typescript prettier eslint || warn "falha nos globais node"
  ok "Node toolkit pronto"
else
  warn "npm ausente — rode 03/04 antes"
fi

# ===========================================================================
section "Rust toolkit (cargo + rustup)"
# ===========================================================================
[[ -s "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"
if have cargo; then
  # rust-analyzer como componente do rustup (LSP p/ editores)
  rustup component add rust-analyzer 2>/dev/null || true
  # Extensões. cargo-binstall acelera (baixa binário pronto em vez de compilar).
  if ! have cargo-binstall; then
    log "Instalando cargo-binstall (acelera as próximas instalações)"
    curl -L --proto '=https' --tlsv1.2 -fsSL \
      https://raw.githubusercontent.com/cargo-bins/cargo-binstall/main/install-from-binstall-release.sh | bash || true
    [[ -s "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"
  fi
  CARGO_INSTALL=(cargo install); have cargo-binstall && CARGO_INSTALL=(cargo binstall -y)
  for ext in cargo-watch cargo-nextest cargo-audit cargo-edit cargo-update sccache; do
    log "${CARGO_INSTALL[*]} $ext"
    "${CARGO_INSTALL[@]}" "$ext" || cargo install "$ext" || warn "falha em $ext"
  done
  ok "Rust toolkit pronto"
else
  warn "cargo ausente — rode 11-rust antes"
fi

section "Toolkits por linguagem concluídos"
