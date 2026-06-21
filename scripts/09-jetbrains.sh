#!/usr/bin/env bash
# JetBrains Toolbox — instala o Toolbox, que gerencia as IDEs.
# IDEs detectadas na máquina (instale-as pelo Toolbox após abri-lo):
#   IntelliJ IDEA, GoLand, PyCharm, WebStorm, DataGrip, RustRover, AIR
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

section "JetBrains Toolbox + IDEs"

# Toolbox e IDEs ficam juntos em ~/Develop/Tools/JetBrains.
# O Toolbox usa por padrão $XDG_DATA_HOME/JetBrains/Toolbox
# (~/.local/share/JetBrains/Toolbox) e recriaria lá; por isso deixamos esse
# caminho como um symlink apontando para o local em ~/Develop/Tools.
JB_DIR="$HOME/Develop/Tools/JetBrains"
TOOLBOX_DIR="$JB_DIR/Toolbox"
XDG_TOOLBOX="$HOME/.local/share/JetBrains/Toolbox"
BIN_DIR="$TOOLBOX_DIR/bin"
TOOLBOX_BIN="$BIN_DIR/jetbrains-toolbox"

mkdir -p "$JB_DIR" "$(dirname "$XDG_TOOLBOX")"
# Migra instalação antiga (dir real no caminho padrão) para Develop/Tools
if [[ -d "$XDG_TOOLBOX" && ! -L "$XDG_TOOLBOX" ]]; then
  if [[ -e "$TOOLBOX_DIR" ]]; then rm -rf "$XDG_TOOLBOX"; else mv "$XDG_TOOLBOX" "$TOOLBOX_DIR"; fi
fi
# Garante o symlink do caminho padrão -> Develop/Tools/JetBrains/Toolbox
ln -sfn "$TOOLBOX_DIR" "$XDG_TOOLBOX"

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
  # '|| true': sob set -e/pipefail, o head -1 fecha o pipe e o grep sai com
  # SIGPIPE (141), o que mataria o script antes do download. Tratamos url vazia.
  # A API devolve x86_64 (sem sufixo) e arm64 (sufixo -arm64); selecionamos
  # conforme a arquitetura — antes o head -1 pegava arm64 numa máquina x86_64.
  tb_urls="$(curl -fsSL 'https://data.services.jetbrains.com/products/releases?code=TBA&latest=true&type=release' \
        | grep -oE 'https://[^"]+jetbrains-toolbox-[^"]+\.tar\.gz' || true)"
  if [[ "$(uname -m)" == "aarch64" ]]; then
    url="$(echo "$tb_urls" | grep -- '-arm64' | head -1 || true)"
  else
    url="$(echo "$tb_urls" | grep -v -- '-arm64' | head -1 || true)"
  fi
  if [[ -z "$url" ]]; then
    warn "Não consegui resolver a URL do Toolbox. Baixe manualmente em https://www.jetbrains.com/toolbox-app/"
    rm -rf "$tmp"
  else
    curl -fsSL "$url" -o "$tmp/toolbox.tar.gz"
    tar -xzf "$tmp/toolbox.tar.gz" -C "$tmp"

    # BUG ANTERIOR: o Toolbox era iniciado a partir do diretório temporário e
    # logo em seguida 'rm -rf "$tmp"' apagava o binário antes dele se instalar.
    # Agora copiamos o binário para um local PERSISTENTE e só então removemos o tmp.
    # O binário fica em <dir-versionado>/bin/jetbrains-toolbox (profundidade 3),
    # então não limitamos o -maxdepth (antes era 2 e não o encontrava).
    extracted="$(find "$tmp" -type f -name 'jetbrains-toolbox' | head -1)"
    if [[ -z "$extracted" ]]; then
      warn "Binário do Toolbox não encontrado no pacote baixado"
      rm -rf "$tmp"
    else
      # O Toolbox 3.5+ é um diretório: o executável precisa do JRE empacotado
      # ao lado (bin/jre, bin/lib). Copiar só o binário causa
      # "Cannot load .../bin/jre/lib/server/libjvm.so → Failed to start JVM".
      # Por isso copiamos a pasta bin/ inteira para o local persistente.
      src_bin_dir="$(dirname "$extracted")"
      mkdir -p "$BIN_DIR"
      cp -a "$src_bin_dir/." "$BIN_DIR/"
      chmod 755 "$TOOLBOX_BIN"
      rm -rf "$tmp"   # seguro: a app já está em $BIN_DIR
      ok "Toolbox instalado em $TOOLBOX_BIN"
    fi
  fi
fi

# --- Local de instalação das IDEs (~/Develop/Tools) ---
# Configura o Toolbox para instalar as IDEs nessa pasta, em vez do padrão
# (~/.local/share/JetBrains/Toolbox/apps). Vale mesmo se o Toolbox já existia.
if [[ -x "$TOOLBOX_BIN" ]]; then
  TOOLS_DIR="$JB_DIR"   # IDEs ao lado do Toolbox, em ~/Develop/Tools/JetBrains
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

  Toolbox e IDEs ficam em: ~/Develop/Tools/JetBrains
    (o caminho padrão ~/.local/share/JetBrains/Toolbox vira symlink p/ lá)

  O PATH dos scripts do Toolbox já está no ~/.profile:
    $PATH:~/Develop/Tools/JetBrains/Toolbox/scripts
EOF

ok "Etapa JetBrains concluída (instalação das IDEs é feita no app Toolbox)"
