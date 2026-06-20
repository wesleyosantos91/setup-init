#!/usr/bin/env bash
# JetBrains Toolbox — instala o Toolbox, que gerencia as IDEs.
# IDEs detectadas na máquina (instale-as pelo Toolbox após abri-lo):
#   IntelliJ IDEA, GoLand, PyCharm, WebStorm, DataGrip, RustRover, AIR
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

section "JetBrains Toolbox + IDEs"

TOOLBOX_DIR="$HOME/.local/share/JetBrains/Toolbox"

if [[ -d "$TOOLBOX_DIR/bin" ]]; then
  ok "JetBrains Toolbox já instalado"
else
  log "Baixando JetBrains Toolbox"
  tmp="$(mktemp -d)"
  # Resolve o link mais recente via API oficial
  url="$(curl -fsSL 'https://data.services.jetbrains.com/products/releases?code=TBA&latest=true&type=release' \
        | grep -oE 'https://[^"]+jetbrains-toolbox-[^"]+\.tar\.gz' | head -1)"
  if [[ -z "$url" ]]; then
    warn "Não consegui resolver a URL do Toolbox. Baixe manualmente em https://www.jetbrains.com/toolbox-app/"
  else
    curl -fsSL "$url" -o "$tmp/toolbox.tar.gz"
    tar -xzf "$tmp/toolbox.tar.gz" -C "$tmp"
    "$tmp"/jetbrains-toolbox-*/jetbrains-toolbox &
    ok "Toolbox iniciado — faça login e instale as IDEs abaixo"
  fi
  rm -rf "$tmp"
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

  O PATH dos scripts do Toolbox já está no ~/.profile:
    $PATH:~/.local/share/JetBrains/Toolbox/scripts
EOF

ok "Etapa JetBrains concluída (instalação das IDEs é feita no app Toolbox)"
