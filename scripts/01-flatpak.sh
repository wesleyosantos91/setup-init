#!/usr/bin/env bash
# Aplicativos Flatpak (VS Code, Flameshot, Insomnia).
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

section "Aplicativos Flatpak"

if ! have flatpak; then
  log "Instalando flatpak"
  sudo dnf -y install flatpak
fi

# Repositório Flathub
if ! flatpak remote-list | grep -q flathub; then
  log "Adicionando remote Flathub"
  sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
fi

APPS=(
  com.visualstudio.code     # Visual Studio Code
  org.flameshot.Flameshot   # Flameshot (screenshots)
  rest.insomnia.Insomnia    # Insomnia (REST client)
)

for app in "${APPS[@]}"; do
  if flatpak list --app | grep -q "$app"; then
    ok "$app já instalado"
  else
    log "Instalando $app"
    sudo flatpak install -y flathub "$app"
  fi
done

ok "Flatpaks prontos"
