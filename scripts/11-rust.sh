#!/usr/bin/env bash
# Rust via rustup (toolchain stable + cargo, rustfmt, clippy).
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

section "Rust (rustup)"

if have rustc && [[ -d "$HOME/.rustup" ]]; then
  ok "Rust já instalado ($(rustc --version 2>/dev/null))"
else
  log "Instalando rustup + toolchain stable"
  # -y: não interativo | --no-modify-path: o PATH já vem do ~/.cargo via dotfiles
  curl --proto '=https' --tlsv1.2 -fsSL https://sh.rustup.rs \
    | sh -s -- -y --default-toolchain stable --profile default --no-modify-path
fi

# Carrega o cargo nesta sessão
[[ -s "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"

if have rustup; then
  # Garante a versão estável mais recente (atualiza se já estava instalado)
  log "Atualizando para o stable mais recente"
  rustup toolchain install stable --profile default
  rustup update stable
  rustup default stable

  log "Garantindo componentes rustfmt e clippy"
  rustup component add rustfmt clippy 2>/dev/null || true
  ok "Rust pronto: $(rustc --version) | $(cargo --version)"
else
  warn "rustup não ficou disponível no PATH desta sessão; abra novo terminal."
fi
