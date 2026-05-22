# dotfiles

Managed via a bare Git repository using:

```bash
git --git-dir=$HOME/.dotfiles --work-tree=$HOME
```

Based on the Atlassian bare repo dotfiles approach.

---

## What's tracked

| File | Purpose |
|---|---|
| `.tmux.conf` | tmux configuration |
| `.config/fish/config.fish` | Fish shell config + abbreviations |
| `.config/mise/config.toml` | Mise tool versions |
| `.gitconfig` | Git configuration |
| `.dotfiles-bootstrap.sh` | Bootstrap script |
| `.profile` | PATH setup for mise shims |

Separate repository:

- Neovim config: https://github.com/yerdzxc/nvim

---

## Security

Only non-sensitive configs are tracked.

Never commit:

- API keys
- tokens
- `.env` files
- SSH private keys
- cloud credentials
- personal secrets

Use:

- environment variables
- password managers
- secret management systems

instead of storing secrets in dotfiles.

---

## Bootstrap

Supported platforms:

- Linux x86_64
- Linux arm64
- macOS Intel
- macOS Apple Silicon

Interactive install:

```bash
curl -fsSL https://raw.githubusercontent.com/yerdzxc/dotfiles/master/.dotfiles-bootstrap.sh | bash
```

Non-interactive install:

```bash
curl -fsSL https://raw.githubusercontent.com/yerdzxc/dotfiles/master/.dotfiles-bootstrap.sh | bash -s -- -y
```

---

## Installed Components

### Runtime / Tool Manager

- mise

### Shell / CLI Tools

Installed through mise:

- neovim
- tmux
- lazygit
- bat
- eza
- fd
- fzf
- ripgrep
- zoxide
- go
- gh

### Language Servers

Installed through bun:

- typescript-language-server
- yaml-language-server
- bash-language-server
- dockerfile-language-server-nodejs
- vscode-langservers-extracted

Native binaries:

- terraform-ls
- lua-language-server

### SSH Config

Security hardening and performance optimizations (applied by bootstrap, existing settings preserved):

- `StrictHostKeyChecking ask` — verify host keys
- `ForwardAgent no` / `ForwardX11 no` — prevent forwarding leaks
- `PasswordAuthentication no` / `ChallengeResponseAuthentication no` — key-only auth
- `LogLevel VERBOSE` — log fingerprints for MITM detection
- `GSSAPIAuthentication no` — skip Kerberos, faster connects
- `ServerAliveInterval 60` — keep NAT sessions alive
- `ControlMaster auto` — connection multiplexing

---

## Usage

Recommended shell function:

```bash
dotfiles() {
  git --git-dir="$HOME/.dotfiles" --work-tree="$HOME" "$@"
}
```

Examples:

```bash
dotfiles status

dotfiles add .config/fish/config.fish

dotfiles commit -m "update fish config"

dotfiles push
```

List tracked files:

```bash
dotfiles ls-files
```

---

## Troubleshooting

### `command not found: dotfiles`

Older versions used a Bash alias inside scripts.

Aliases are not expanded in non-interactive shells by default.

Fixed by using a shell function instead.

### Checkout conflicts

If bootstrap reports checkout conflicts:

```bash
git --git-dir=$HOME/.dotfiles --work-tree=$HOME checkout
```

Then move or back up conflicting files before retrying.

### mise shims not detected

Restart shell:

```bash
exec fish
```

or:

```bash
source ~/.profile
```

---

## Philosophy

This setup prioritizes:

- reproducible environments
- minimal dependencies
- cross-platform compatibility
- fast terminal workflows
- clean developer onboarding
