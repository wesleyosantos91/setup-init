#!/usr/bin/env bash
# JetBrains Toolbox — instala o Toolbox, que gerencia as IDEs.
# IDEs detectadas na máquina (instale-as pelo Toolbox após abri-lo):
#   IntelliJ IDEA, GoLand, PyCharm, WebStorm, DataGrip, RustRover, AIR
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

section "JetBrains Toolbox + IDEs"

TOOLBOX_DIR="$HOME/.local/share/JetBrains/Toolbox"
BIN_DIR="$TOOLBOX_DIR/bin"
TOOLBOX_BIN="$BIN_DIR/jetbrains-toolbox"

if [[ -x "$TOOLBOX_BIN" ]]; then
  ok "JetBrains Toolbox já instalado"
else
  log "Baixando JetBrains Toolbox"

  # O Toolbox é um AppImage e precisa do FUSE2 (libfuse.so.2) para montar-se.
  # Sem ele, o app não abre e nenhuma IDE é instalada.
  if ! ldconfig -p 2>/dev/null | grep -q 'libfuse\.so\.2'; then
    log "Instalando dependência FUSE (necessária pelo AppImage do Toolbox)"
    sudo dnf -y install fuse fuse-libs 2>/dev/null \
      || warn "Não instalei o FUSE; usarei extração do AppImage como alternativa"
  fi

  tmp="$(mktemp -d)"
  # Resolve o link mais recente via API oficial
  url="$(curl -fsSL 'https://data.services.jetbrains.com/products/releases?code=TBA&latest=true&type=release' \
        | grep -oE 'https://[^"]+jetbrains-toolbox-[^"]+\.tar\.gz' | head -1)"
  if [[ -z "$url" ]]; then
    warn "Não consegui resolver a URL do Toolbox. Baixe manualmente em https://www.jetbrains.com/toolbox-app/"
    rm -rf "$tmp"
  else
    curl -fsSL "$url" -o "$tmp/toolbox.tar.gz"
    tar -xzf "$tmp/toolbox.tar.gz" -C "$tmp"

    # BUG ANTERIOR: o Toolbox era iniciado a partir do diretório temporário e
    # logo em seguida 'rm -rf "$tmp"' apagava o binário antes dele se instalar.
    # Agora copiamos o binário para um local PERSISTENTE e só então removemos o tmp.
    extracted="$(find "$tmp" -maxdepth 2 -type f -name 'jetbrains-toolbox' | head -1)"
    if [[ -z "$extracted" ]]; then
      warn "Binário do Toolbox não encontrado no pacote baixado"
      rm -rf "$tmp"
    else
      mkdir -p "$BIN_DIR"
      install -m 755 "$extracted" "$TOOLBOX_BIN"
      rm -rf "$tmp"   # seguro: o binário já está em $TOOLBOX_BIN
      ok "Toolbox instalado em $TOOLBOX_BIN"
    fi
  fi
fi

# --- Local de instalação das IDEs (~/Develop/Tools) ---
# Configura o Toolbox para instalar as IDEs nessa pasta, em vez do padrão
# (~/.local/share/JetBrains/Toolbox/apps). Vale mesmo se o Toolbox já existia.
if [[ -x "$TOOLBOX_BIN" ]]; then
  TOOLS_DIR="$HOME/Develop/Tools"
  mkdir -p "$TOOLS_DIR"
  SETTINGS_FILE="$TOOLBOX_DIR/.settings.json"
  log "Definindo local de instalação das IDEs: $TOOLS_DIR"
  if have jq && [[ -f "$SETTINGS_FILE" ]]; then
    # Preserva as demais configurações existentes
    tmp_s="$(mktemp)"
    if jq --arg p "$TOOLS_DIR" '.install_location = $p' "$SETTINGS_FILE" > "$tmp_s"; then
      mv "$tmp_s" "$SETTINGS_FILE"
    else
      rm -f "$tmp_s"; warn "Não consegui atualizar $SETTINGS_FILE"
    fi
  else
    cat > "$SETTINGS_FILE" <<JSON
{
  "install_location": "$TOOLS_DIR"
}
JSON
  fi
  ok "IDEs serão instaladas em $TOOLS_DIR"

  # --- Inicia o Toolbox (login + instalação das IDEs) ---
  if [[ -n "${DISPLAY:-}${WAYLAND_DISPLAY:-}" ]]; then
    log "Iniciando o Toolbox (faça login e instale as IDEs abaixo)"
    # Se o FUSE não estiver presente, extrai o AppImage em vez de montá-lo.
    if ldconfig -p 2>/dev/null | grep -q 'libfuse\.so\.2'; then
      nohup "$TOOLBOX_BIN" >/dev/null 2>&1 &
    else
      APPIMAGE_EXTRACT_AND_RUN=1 nohup "$TOOLBOX_BIN" >/dev/null 2>&1 &
    fi
    disown
    ok "Toolbox iniciado"
  else
    warn "Sem sessão gráfica (DISPLAY/WAYLAND) — abra manualmente: $TOOLBOX_BIN"
  fi
fi

cat <<'EOF'

  IDEs a instalar pelo Toolbox (estavam presentes na máquina):
    • IntelliJ IDEA
    • GoLand
    • PyCharm
    • WebStorm
    • DataGrip
    • RustRover
    • AIR

  As IDEs serão instaladas em: ~/Develop/Tools

  O PATH dos scripts do Toolbox já está no ~/.profile:
    $PATH:~/.local/share/JetBrains/Toolbox/scripts
EOF

ok "Etapa JetBrains concluída (instalação das IDEs é feita no app Toolbox)"
