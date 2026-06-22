#!/usr/bin/env bash
# =============================================================================
#  setup.sh — Restaura o ambiente de desenvolvimento desta máquina
#  Alvo: Red Hat Enterprise Linux 9 (RHEL 9 / dnf)
#  Usuário de referência: wesleyosantos
#
#  Uso:
#    ./setup.sh                 # roda todas as etapas, em ordem
#    ./setup.sh 00 03 04        # roda apenas etapas específicas (por prefixo)
#    ./setup.sh --list          # lista as etapas
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/scripts/lib.sh"

STEPS=(
  "00-system-packages.sh"   # dnf: docker, gh, git, build tools, etc.
  "01-flatpak.sh"           # VS Code, Flameshot, Insomnia
  "02-shell-zsh-omz.sh"     # zsh + oh-my-zsh + p10k + plugins
  "03-version-managers.sh"  # SDKMAN, nvm, pyenv, goenv, rustup
  "04-sdks.sh"              # Java/Maven/Gradle, Node, Python, Go, Rust (versões fixas)
  "05-npm-globals.sh"       # pacotes npm globais
  "06-cli-tools.sh"         # claude, codex, agy, rtk
  "07-dotfiles.sh"          # restaura .zshrc, .gitconfig, ssh, gh, etc.
  "08-git-github.sh"        # gh auth login + verificação
  "09-jetbrains.sh"         # JetBrains Toolbox + IDEs
  "10-docker.sh"            # serviço docker + grupo
  "11-kiro.sh"              # Kiro Desktop + Kiro CLI
  "12-fonts.sh"             # fontes do usuário (MesloLGS NF p/ p10k)
  "13-extra-tools.sh"       # delta, fzf, zoxide, bat, fd, direnv, lazygit, etc.
  "14-lang-toolkits.sh"     # toolkits por linguagem (JVM/Go/Python/Node/Rust)
  "99-validate.sh"          # validação final (doctor) — confere tudo
)

if [[ "${1:-}" == "--list" ]]; then
  echo "Etapas disponíveis:"
  for s in "${STEPS[@]}"; do echo "  - $s"; done
  exit 0
fi

run_step() {
  local script="$SCRIPT_DIR/scripts/$1"
  echo -e "\n${C_GREEN}==================================================${C_RESET}"
  echo -e "${C_GREEN}>>> $1${C_RESET}"
  echo -e "${C_GREEN}==================================================${C_RESET}"
  bash "$script"
}

# Filtra por prefixos passados como argumento (ex.: 00 03)
SELECTED=("${STEPS[@]}")
if [[ $# -gt 0 ]]; then
  SELECTED=()
  for prefix in "$@"; do
    for s in "${STEPS[@]}"; do
      [[ "$s" == "$prefix"* ]] && SELECTED+=("$s")
    done
  done
fi

log "Iniciando setup. Pode ser pedida a senha do sudo."
for s in "${SELECTED[@]}"; do
  run_step "$s"
done

section "Setup concluído"
cat <<'EOF'

  Próximos passos manuais:
    1. Abra um novo terminal (zsh) para carregar os gerenciadores de versão.
    2. JetBrains: abra o Toolbox e instale as IDEs (IntelliJ, GoLand, PyCharm,
       WebStorm, DataGrip, RustRover, AIR).
    3. GitHub: se não autenticou, rode  gh auth login -h github.com -p ssh
    4. Docker: faça logout/login para o grupo 'docker' valer.
    5. Confira a chave de assinatura SSH no GitHub (Settings > SSH and GPG keys
       > Signing keys) caso precise reassinar commits.

EOF
