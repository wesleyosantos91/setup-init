#!/usr/bin/env bash
# Ferramentas de linha de comando instaladas em ~/.local/bin:
#   - Claude Code (claude)
#   - Codex CLI (codex)        -> também disponível via npm (@openai/codex)
#   - Antigravity CLI (agy)
#   - rtk (Rust Token Killer)
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

section "CLIs de IA / produtividade (~/.local/bin)"

mkdir -p "$HOME/.local/bin"

# --- Claude Code ---
if have claude; then
  log "claude presente — atualizando"
  claude update >/dev/null 2>&1 || warn "não atualizou o claude (siga manualmente se preciso)"
else
  log "Instalando Claude Code"
  curl -fsSL https://claude.ai/install.sh | bash || \
    warn "Falha ao instalar Claude Code automaticamente. Veja https://docs.claude.com/claude-code"
fi

# --- Antigravity CLI (agy) ---
if have agy; then
  log "agy (Antigravity) presente — tentando atualizar"
  agy update >/dev/null 2>&1 || curl -fsSL https://antigravity.google/install.sh | bash || \
    warn "não atualizou o agy"
else
  log "Instalando Antigravity CLI (agy)"
  curl -fsSL https://antigravity.google/install.sh | bash || \
    warn "Falha ao instalar Antigravity CLI. Instale manualmente o 'agy'."
fi

# --- Codex CLI ---
# Já é instalado via npm global (@openai/codex) no script 05.
if have codex; then
  ok "codex já disponível"
else
  warn "codex não encontrado — será instalado via npm global (script 05)"
fi

# --- rtk (Rust Token Killer) ---
if have rtk; then
  ok "rtk já instalado"
else
  warn "rtk (Rust Token Killer) não tem instalador público padrão."
  warn "Reinstale o binário em ~/.local/bin/rtk conforme sua fonte original."
fi

ok "CLIs processadas"
