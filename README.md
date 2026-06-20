# setup-init — Restauração do ambiente de desenvolvimento

Scripts para reconstruir esta máquina **exatamente como está hoje** após uma
formatação. Alvo: **Red Hat Enterprise Linux 9 e 10** (`dnf4`/`dnf5`).

## Como usar

```bash
# 1. Copie esta pasta inteira para a máquina nova (inclua a pasta secrets/!)
# 2. Rode tudo:
chmod +x setup.sh scripts/*.sh
./setup.sh

# Ou rode etapas específicas (por prefixo):
./setup.sh 00 03 04
./setup.sh --list
```

> O script usa `sudo` em algumas etapas (dnf, docker, chsh). A senha será pedida.

## O que é restaurado

| Etapa | Conteúdo |
|-------|----------|
| `00-system-packages` | Repos Docker CE e GitHub CLI; `git gh jq make gcc gcc-c++ cmake automake curl wget tree vim zsh` + libs de build (para pyenv/goenv); **Docker CE** completo |
| `01-flatpak` | Flathub + **VS Code**, **Flameshot**, **Insomnia** |
| `02-shell-zsh-omz` | **Oh My Zsh**, tema **Powerlevel10k**, plugins `zsh-autosuggestions` e `zsh-syntax-highlighting`; define `zsh` como shell padrão |
| `03-version-managers` | **SDKMAN**, **nvm**, **pyenv**, **goenv** |
| `04-sdks` | Java **25.0.3-tem**, Maven **3.9.16**, Gradle **9.6.0**, Node **22.23.0** (default) + **24.17.0**, Python **3.13.14**, Go **1.26.4** |
| `05-npm-globals` | `@devcontainers/cli`, `@fission-ai/openspec`, `@github/copilot`, `@google/gemini-cli`, `@openai/codex`, `corepack`, `repomix` |
| `06-cli-tools` | **Claude Code** (`claude`), **Codex** (`codex`), **Antigravity** (`agy`), **rtk** |
| `07-dotfiles` | `.zshrc .bashrc .bash_profile .profile .p10k.zsh .gitconfig .gitignore_global .gitconfig-itau`, config git de assinatura (`allowed_signers`), config do `gh`, `~/.ssh/config` e **chaves SSH** |
| `08-git-github` | `gh auth login` (interativo) + verificação da config git |
| `09-jetbrains` | **JetBrains Toolbox** (instale as IDEs por ele: IntelliJ, GoLand, PyCharm, WebStorm, DataGrip, RustRover, AIR) |
| `10-docker` | habilita o serviço `docker` e adiciona o usuário ao grupo `docker` |
| `11-rust` | **Rust** via `rustup` (toolchain `stable` + `cargo`, `rustfmt`, `clippy`) |
| `12-fonts` | Fontes do usuário — **MesloLGS NF** (Nerd Font usada pelo Powerlevel10k) |
| `13-extra-tools` | EPEL + **git-delta, fzf, zoxide, bat, fd, direnv, btop, tmux, ShellCheck, yq** (dnf); **lazygit, lazydocker, gitleaks** (binário GitHub); **tldr/tealdeer** (cargo); **pre-commit** (pip) |
| `14-lang-toolkits` | **JVM**: mvnd, springboot, jbang · **Go**: golangci-lint, goimports, dlv, govulncheck, air, mockgen · **Python**: uv, pipx, ruff, mypy, pytest · **Node**: pnpm/yarn (corepack) + typescript, prettier, eslint · **Rust**: cargo-watch, cargo-nextest, cargo-audit, cargo-edit, cargo-update, sccache, rust-analyzer |
| `99-validate` | **Doctor**: confere todas as ferramentas/configs e imprime ✅ "TUDO COM SUCESSO" ou lista o que faltou |

> Para validar a qualquer momento (sem reinstalar): `./setup.sh 99`

## ⚠️ Segredos (pasta `secrets/`)

Contém suas **chaves SSH privadas** (`id_rsa_github`, `id_rsa_git_signing`) e
`known_hosts`. São restauradas em `~/.ssh` com permissão `600`.

- **NÃO** suba esta pasta para um repositório Git público.
- Guarde-a em local seguro (pendrive criptografado, gerenciador de segredos).
- O token do `gh` **não** está aqui (fica no keyring do sistema) — por isso a
  etapa 08 refaz o `gh auth login`.

Um `.gitignore` já exclui `secrets/` e os backups `*.bak.*`.

---

# 📋 Passos manuais detalhados

Algumas coisas **não dá para automatizar** (login interativo, senha de sudo,
tokens que ficam no keyring, GUIs). Abaixo o passo a passo de cada uma.

## 1. Senha do `sudo` (etapas 00, 01, 10, 13)

As etapas que instalam pacotes de sistema, Flatpaks, Docker e EPEL usam `sudo`.
Ao rodar `./setup.sh`, o terminal vai pedir sua senha — basta digitar.
Se estiver rodando dentro do Claude Code, execute essas etapas você mesmo:

```bash
./setup.sh 00 01 10 13      # pede a senha do sudo no seu terminal
```

## 2. GitHub — autenticação (`gh auth login`)

O **token do GitHub não pode ser salvo no backup** (fica no keyring do sistema).
Depois de formatar, reautentique. A etapa 08 já faz isso, mas o passo é:

```bash
gh auth login -h github.com -p ssh -s admin:public_key,gist,read:org,repo
```

1. Escolha **GitHub.com**
2. Protocolo: **SSH**
3. Selecione a chave `~/.ssh/id_rsa_github.pub` (ou deixe o gh detectar)
4. Autentique pelo **navegador** (login na conta `wesleyosantos91`) ou cole um token
5. Confirme com `gh auth status`

> Escopos necessários: `admin:public_key, gist, read:org, repo`
> (o `admin:public_key` é o que permite a etapa 08 cadastrar suas chaves SSH).

## 3. GitHub — cadastrar as chaves SSH na conta

As chaves **privadas** são restauradas do backup (`secrets/`) pela etapa 07.
As **públicas** precisam estar cadastradas na sua conta do GitHub:

- **Se você usar a MESMA chave do backup** → ela já está cadastrada lá, nada a fazer.
- **Se gerar chave nova** → a etapa 08 tenta cadastrar automaticamente via
  `gh ssh-key add` (precisa do `gh` autenticado com escopo `admin:public_key`).

Cadastro manual, se preferir, em **Settings → SSH and GPG keys**:

```bash
# chave de autenticação
gh ssh-key add ~/.ssh/id_rsa_github.pub      --title "minha-maquina-auth"    --type authentication
# chave de ASSINATURA (commits assinados)
gh ssh-key add ~/.ssh/id_rsa_git_signing.pub --title "minha-maquina-signing" --type signing
```

> ⚠️ A chave de **assinatura** é separada da de autenticação no GitHub. Sem ela
> cadastrada como *Signing key*, seus commits aparecem como "Unverified".

## 4. Validar commits assinados (SSH signing)

Seu `.gitconfig` assina commits/tags por padrão (`commit.gpgsign = true`,
formato `ssh`). Para conferir que está tudo certo:

```bash
ssh-add ~/.ssh/id_rsa_git_signing            # adiciona a chave ao agent
git commit --allow-empty -m "test: assinatura"
git log --show-signature -1                   # deve mostrar "Good signature"
```

Se der erro de chave, confirme:
- `~/.ssh/id_rsa_git_signing` existe e tem permissão `600`
- `~/.config/git/allowed_signers` foi restaurado (etapa 07)

## 5. IDEs JetBrains (via Toolbox)

A etapa 09 instala o **JetBrains Toolbox**, mas as IDEs e o login são manuais:

1. Abra o **JetBrains Toolbox** (já iniciado pela etapa 09)
2. Faça login na sua conta JetBrains (licença)
3. Instale: **IntelliJ IDEA, GoLand, PyCharm, WebStorm, DataGrip, RustRover, AIR**
4. O PATH dos atalhos (`idea`, `goland`, ...) já está no `~/.profile`

## 6. Docker sem `sudo` (relogin)

A etapa 10 adiciona seu usuário ao grupo `docker`, mas o grupo só vale após
**logout/login** (ou rode `newgrp docker` para a sessão atual). Teste:

```bash
docker run --rm hello-world
```

## 7. `rtk` (Rust Token Killer)

Não tem instalador público padrão. Reponha o binário manualmente:

```bash
cp /caminho/do/seu/rtk ~/.local/bin/rtk && chmod +x ~/.local/bin/rtk
rtk --version
```

## 8. Trocar o shell padrão para zsh (se necessário)

A etapa 02 tenta `chsh` automaticamente. Se falhar (precisa de senha):

```bash
chsh -s "$(which zsh)"     # efeito após novo login
```

## 9. Logins das CLIs de IA

`claude`, `codex`, `gemini`, `copilot` e `agy` são instalados, mas o **login de
cada um é interativo** na primeira execução (abrem navegador/pedem token):

```bash
claude        # primeira execução pede login
codex login
gemini        # segue o fluxo de auth
```

---

> Resumo do que é 100% manual e por quê:
> **senha do sudo** (segurança), **gh auth login / logins de IA** (token no keyring),
> **IDEs JetBrains** (licença/GUI), **rtk** (sem instalador público).
> Todo o resto é automatizado pelos scripts.

---

## 📄 Licença

Copyright © 2026 **Wesley Oliveira** <wesleyosantos91@gmail.com>

Licenciado sob **[CC BY-NC-SA 4.0](https://creativecommons.org/licenses/by-nc-sa/4.0/)**
(Atribuição · Não-Comercial · Compartilha-Igual):

- ✅ Pode **usar, estudar, modificar e redistribuir** livremente.
- ✅ Deve **manter o código público/aberto** e sob esta mesma licença (ShareAlike).
- ✅ Deve **dar crédito** ao autor (Attribution).
- ❌ **Proibido uso comercial / venda** (NonCommercial).

Veja o arquivo [`LICENSE`](./LICENSE) para o texto legal completo.
