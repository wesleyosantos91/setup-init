#!/usr/bin/env bash
# Instala as versões específicas de cada SDK/linguagem capturadas da máquina.
# Requer que 03-version-managers.sh tenha rodado antes (SDKMAN, nvm, pyenv, goenv, rustup).
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

section "SDKs e linguagens (versões fixadas)"

# ---------------------------------------------------------------------------
# SDKMAN: Java, Maven, Gradle
# ---------------------------------------------------------------------------
export SDKMAN_DIR="$HOME/.sdkman"
if [[ -s "$SDKMAN_DIR/bin/sdkman-init.sh" ]]; then
  set +u; source "$SDKMAN_DIR/bin/sdkman-init.sh"; set -u
  log "SDKMAN: instalando Java 25.0.3-tem / Maven 3.9.16 / Gradle 9.6.0"
  # SDKMAN usa parâmetros posicionais opcionais ($3, etc.) internamente;
  # desativamos nounset durante as chamadas para evitar "variável não associada".
  set +u
  sdk install java   25.0.3-tem || true
  sdk install maven  3.9.16     || true
  sdk install gradle 9.6.0      || true
  sdk default java   25.0.3-tem || true
  sdk default maven  3.9.16     || true
  sdk default gradle 9.6.0      || true
  set -u
  ok "SDKMAN configurado"
else
  warn "SDKMAN não encontrado — rode 03-version-managers.sh antes"
fi

# ---------------------------------------------------------------------------
# nvm: Node v22.23.0 (default) e v24.17.0
# ---------------------------------------------------------------------------
export NVM_DIR="$HOME/.nvm"
if [[ -s "$NVM_DIR/nvm.sh" ]]; then
  set +u; source "$NVM_DIR/nvm.sh"; set -u
  log "nvm: instalando Node v22.23.0 e v24.17.0"
  nvm install 22.23.0
  nvm install 24.17.0
  nvm alias default 22
  ok "nvm configurado (default = 22)"
else
  warn "nvm não encontrado — rode 03-version-managers.sh antes"
fi

# ---------------------------------------------------------------------------
# pyenv: Python 3.13.14
# ---------------------------------------------------------------------------
export PYENV_ROOT="$HOME/.pyenv"
if [[ -d "$PYENV_ROOT/bin" ]]; then
  export PATH="$PYENV_ROOT/bin:$PATH"
  eval "$(pyenv init -)"
  log "pyenv: instalando Python 3.13.14 (pode demorar — compila do fonte)"
  pyenv install -s 3.13.14
  pyenv global 3.13.14
  ok "pyenv configurado (global = 3.13.14)"
else
  warn "pyenv não encontrado — rode 03-version-managers.sh antes"
fi

# ---------------------------------------------------------------------------
# goenv: Go 1.26.4
# ---------------------------------------------------------------------------
export GOENV_ROOT="$HOME/.goenv"
if [[ -d "$GOENV_ROOT/bin" ]]; then
  export PATH="$GOENV_ROOT/bin:$PATH"
  eval "$(goenv init -)"
  log "goenv: instalando Go 1.26.4"
  goenv install -s 1.26.4
  goenv global 1.26.4
  ok "goenv configurado (global = 1.26.4)"
else
  warn "goenv não encontrado — rode 03-version-managers.sh antes"
fi

# ---------------------------------------------------------------------------
# rustup: Rust stable + rustfmt + clippy
# ---------------------------------------------------------------------------
# shellcheck source=/dev/null
[[ -s "$HOME/.cargo/env" ]] && { set +u; source "$HOME/.cargo/env"; set -u; }
if have rustup; then
  log "Rust: garantindo toolchain stable e componentes"
  set +u
  rustup toolchain install stable --profile default
  rustup update stable
  rustup default stable
  rustup component add rustfmt clippy 2>/dev/null || true
  set -u
  ok "Rust pronto: $(rustc --version) | $(cargo --version)"
else
  warn "rustup não encontrado — rode 03-version-managers.sh antes"
fi

ok "SDKs instalados"
