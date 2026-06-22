#!/usr/bin/env bash
# Kiro Desktop + Kiro CLI.
#
# Desktop:
#   - baixa o Linux Universal pelo metadata oficial do canal stable
#   - instala em ~/Develop/Tools/Kiro
#   - cria o comando "kiro" em ~/.local/bin
#
# CLI:
#   - usa o instalador oficial: https://cli.kiro.dev/install
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

section "Kiro Desktop / CLI"

mkdir -p "$HOME/.local/bin"

TOOLS_DIR="${TOOLS_DIR:-$HOME/Develop/Tools}"
KIRO_APP_DIR="$TOOLS_DIR/Kiro"
KIRO_IDE_METADATA_URL="${KIRO_IDE_METADATA_URL:-https://prod.download.desktop.kiro.dev/stable/metadata-linux-x64-stable.json}"

install_kiro_cli() {
  if have kiro-cli && [[ "${SETUP_UPDATE:-0}" != "1" ]]; then
    ok "kiro-cli já instalado (use SETUP_UPDATE=1 para atualizar)"
    return
  fi

  local tmp installer args=()
  tmp="$(mktemp -d)"
  installer="$tmp/kiro-cli-install.sh"

  log "Instalando Kiro CLI"
  curl -fsSL https://cli.kiro.dev/install -o "$installer"
  [[ "${SETUP_UPDATE:-0}" == "1" ]] && args+=(--force)
  bash "$installer" "${args[@]}" || warn "Falha ao instalar Kiro CLI. Instale manualmente: https://kiro.dev/downloads/"
  rm -rf "$tmp"
}

install_kiro_desktop() {
  if have kiro && kiro --version >/dev/null 2>&1 && [[ "${SETUP_UPDATE:-0}" != "1" ]]; then
    ok "kiro desktop já instalado (use SETUP_UPDATE=1 para atualizar)"
    return
  fi

  case "$(uname -m)" in
    x86_64) ;;
    *)
      warn "Kiro Desktop Linux Universal está automatizado apenas para x86_64; instale manualmente: https://kiro.dev/downloads/"
      return
      ;;
  esac

  local metadata tar_url tmp
  log "Buscando metadata do Kiro Desktop"
  metadata="$(curl -fsSL "$KIRO_IDE_METADATA_URL")"
  tar_url="$(printf '%s' "$metadata" | jq -r '.releases[].updateTo.url | select(endswith(".tar.gz"))' | head -1)"

  if [[ -z "$tar_url" || "$tar_url" == "null" ]]; then
    warn "Não encontrei o tarball Linux no metadata do Kiro Desktop"
    return
  fi

  tmp="$(mktemp -d)"
  log "Baixando Kiro Desktop Linux Universal"
  curl -fsSL "$tar_url" -o "$tmp/kiro.tar.gz"
  tar -xzf "$tmp/kiro.tar.gz" -C "$tmp"

  if [[ ! -x "$tmp/Kiro/bin/kiro" ]]; then
    rm -rf "$tmp"
    warn "Pacote do Kiro Desktop não contém Kiro/bin/kiro"
    return
  fi

  "$tmp/Kiro/bin/kiro" --version >/dev/null

  mkdir -p "$TOOLS_DIR"
  rm -rf "$KIRO_APP_DIR"
  mv "$tmp/Kiro" "$KIRO_APP_DIR"
  ln -sf "$KIRO_APP_DIR/bin/kiro" "$HOME/.local/bin/kiro"
  rm -rf "$tmp"

  ok "kiro desktop instalado em $KIRO_APP_DIR"
}

install_kiro_cli
install_kiro_desktop

ok "Kiro processado"
