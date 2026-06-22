#!/usr/bin/env bash
# Validação final ("doctor"): confere se tudo foi instalado/configurado com sucesso.
# Não usa 'set -e' para conseguir checar tudo e dar um relatório completo no final.
set -o pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

section "Validação final do ambiente"

PASS=0; FAIL=0
declare -a FAILED=()

# Carrega os gerenciadores nesta sessão (para os comandos aparecerem)
export SDKMAN_DIR="$HOME/.sdkman";  [[ -s "$SDKMAN_DIR/bin/sdkman-init.sh" ]] && source "$SDKMAN_DIR/bin/sdkman-init.sh" >/dev/null 2>&1
export NVM_DIR="$HOME/.nvm";        [[ -s "$NVM_DIR/nvm.sh" ]] && source "$NVM_DIR/nvm.sh" >/dev/null 2>&1
export PYENV_ROOT="$HOME/.pyenv";   [[ -d "$PYENV_ROOT/bin" ]] && export PATH="$PYENV_ROOT/bin:$PATH" && eval "$(pyenv init - 2>/dev/null)" >/dev/null 2>&1
export GOENV_ROOT="$HOME/.goenv";   [[ -d "$GOENV_ROOT/bin" ]] && export PATH="$GOENV_ROOT/bin:$PATH" && eval "$(goenv init - 2>/dev/null)" >/dev/null 2>&1
export GOPATH="$HOME/go"
export PATH="$GOPATH/bin:$HOME/.cargo/bin:$HOME/.local/bin:$PATH"
[[ -s "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"

# check_cmd <rótulo> <comando-que-deve-existir>
check_cmd() {
  local label="$1" cmd="$2"
  if command -v "$cmd" >/dev/null 2>&1; then
    ok "$label ($cmd)"
    PASS=$((PASS+1))
  else
    err "$label — FALTANDO ($cmd)"
    FAIL=$((FAIL+1)); FAILED+=("$label:$cmd")
  fi
}

# check_path <rótulo> <arquivo/dir>
check_path() {
  local label="$1" p="$2"
  if [[ -e "$p" ]]; then
    ok "$label"
    PASS=$((PASS+1))
  else
    err "$label — AUSENTE ($p)"
    FAIL=$((FAIL+1)); FAILED+=("$label:$p")
  fi
}

log "Base / sistema"
check_cmd "git"        git
check_cmd "GitHub CLI" gh
check_cmd "Docker"     docker
check_cmd "jq"         jq
check_cmd "zsh"        zsh
check_cmd "make/gcc"   gcc

log "Shell / aparência"
check_path "Oh My Zsh"        "$HOME/.oh-my-zsh"
check_path "Powerlevel10k"    "$HOME/.oh-my-zsh/custom/themes/powerlevel10k"
check_path "Plugin autosuggestions"    "$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions"
check_path "Plugin syntax-highlighting" "$HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting"
check_path ".p10k.zsh"        "$HOME/.p10k.zsh"
check_path "Fonte MesloLGS NF" "$HOME/.local/share/fonts/MesloLGS"

log "Gerenciadores de versão"
check_path "SDKMAN" "$HOME/.sdkman"
check_path "nvm"    "$HOME/.nvm"
check_cmd  "pyenv"  pyenv
check_cmd  "goenv"  goenv

log "SDKs / linguagens"
check_cmd "Java"   java
check_cmd "Maven"  mvn
check_cmd "Gradle" gradle
check_cmd "Node"   node
check_cmd "Python" python
check_cmd "Go"     go
check_cmd "Rust"   rustc
check_cmd "cargo"  cargo

log "Toolkit JVM"
check_cmd "mvnd"       mvnd
check_cmd "springboot" spring
check_cmd "jbang"      jbang

log "Toolkit Go"
check_cmd "golangci-lint" golangci-lint
check_cmd "goimports"     goimports
check_cmd "dlv"           dlv
check_cmd "govulncheck"   govulncheck
check_cmd "air"           air
check_cmd "mockgen"       mockgen

log "Toolkit Python"
check_cmd "uv"     uv
check_cmd "pipx"   pipx
check_cmd "ruff"   ruff
check_cmd "mypy"   mypy
check_cmd "pytest" pytest

log "Toolkit Node"
check_cmd "pnpm"       pnpm
check_cmd "yarn"       yarn
check_cmd "typescript" tsc
check_cmd "prettier"   prettier
check_cmd "eslint"     eslint

log "Toolkit Rust"
check_cmd "cargo-watch"   cargo-watch
check_cmd "cargo-nextest" cargo-nextest
check_cmd "cargo-audit"   cargo-audit

log "CLIs de produtividade / IA"
check_cmd "git-delta" delta
check_cmd "fzf"       fzf
check_cmd "zoxide"    zoxide
check_cmd "bat"       bat
check_cmd "fd"        fd
check_cmd "direnv"    direnv
check_cmd "lazygit"   lazygit
check_cmd "lazydocker" lazydocker
check_cmd "gitleaks"  gitleaks
check_cmd "btop"      btop
check_cmd "tmux"      tmux
check_cmd "shellcheck" shellcheck
check_cmd "pre-commit" pre-commit
check_cmd "claude"    claude
check_cmd "codex"     codex
check_cmd "Kiro CLI"  kiro-cli
check_cmd "Kiro Desktop" kiro

log "Git / GitHub"
check_path ".gitconfig"      "$HOME/.gitconfig"
check_path "allowed_signers" "$HOME/.config/git/allowed_signers"
check_path "chave SSH github"   "$HOME/.ssh/id_rsa_github"
check_path "chave SSH signing"  "$HOME/.ssh/id_rsa_git_signing"
if gh auth status >/dev/null 2>&1; then
  ok "gh autenticado"; PASS=$((PASS+1))
else
  warn "gh NÃO autenticado (passo manual — veja README seção 2)"
fi

# ---------------------------------------------------------------------------
echo
section "Resultado"
echo -e " ${C_GREEN}Passou:${C_RESET} $PASS    ${C_RED}Falhou:${C_RESET} $FAIL"
if [[ $FAIL -eq 0 ]]; then
  echo
  echo -e "${C_GREEN}╔══════════════════════════════════════════════╗${C_RESET}"
  echo -e "${C_GREEN}║   ✅  TUDO FOI INSTALADO COM SUCESSO!  🎉     ║${C_RESET}"
  echo -e "${C_GREEN}╚══════════════════════════════════════════════╝${C_RESET}"
  exit 0
else
  echo
  echo -e "${C_YELLOW}Itens com problema (reveja a etapa correspondente):${C_RESET}"
  for f in "${FAILED[@]}"; do echo "   - ${f%%:*}  (${f##*:})"; done
  echo
  echo -e "${C_YELLOW}Dica:${C_RESET} reabra o terminal (zsh) e rode novamente: ./setup.sh 99"
  exit 1
fi
