#!/usr/bin/env bash
set -euo pipefail

REPO_URL="git@github.com:yerdzxc/dotfiles.git"
NVIM_REPO="git@github.com:yerdzxc/nvim.git"

AUTO=0
[ "${1:-}" = "-y" ] && AUTO=1

ask() {
  [ "$AUTO" = 1 ] && return 0

  echo ""
  read -rp "  Install $1? [Y/n] " ans

  case "${ans:-Y}" in
    y|Y|"") return 0 ;;
    *) return 1 ;;
  esac
}

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "ERROR: required command not found: $1"
    exit 1
  fi
}

dotfiles() {
  git --git-dir="$HOME/.dotfiles" --work-tree="$HOME" "$@"
}

echo ""
echo "========================================"
echo "  dotfiles bootstrap"
echo "  https://github.com/yerdzxc/dotfiles"
echo "========================================"

# ── Prerequisites ──────────────────────────────────────────────

for cmd in git curl tar; do
  require_cmd "$cmd"
done

mkdir -p "$HOME/.local/bin"
mkdir -p "$HOME/.config"

export PATH="$HOME/.local/bin:$HOME/.bun/bin:$PATH"

OS="$(uname -s)"
ARCH="$(uname -m)"

case "$OS-$ARCH" in
  Linux-x86_64)
    OS_ALT="linux"
    ARCH_ALT="amd64"
    ARCH_LS="linux-x64"
    ;;

  Linux-aarch64)
    OS_ALT="linux"
    ARCH_ALT="arm64"
    ARCH_LS="linux-arm64"
    ;;

  Darwin-arm64)
    OS_ALT="darwin"
    ARCH_ALT="arm64"
    ARCH_LS="darwin-arm64"
    ;;

  Darwin-x86_64)
    OS_ALT="darwin"
    ARCH_ALT="amd64"
    ARCH_LS="darwin-x64"
    ;;

  *)
    echo "ERROR: unsupported platform: $OS-$ARCH"
    exit 1
    ;;
esac

# ── Mise ───────────────────────────────────────────────────────

if ask "mise (runtime manager)"; then
  echo "==> Installing mise"

  if ! command -v mise >/dev/null 2>&1; then
    curl -fsSL https://mise.jdx.dev/install.sh | sh
  fi

  eval "$(mise activate bash 2>/dev/null || true)"
fi

# Trust local mise config when running inside cloned dotfiles repo
if [ -d ".git" ] && [ -f ".config/mise/config.toml" ]; then
  echo "==> Trusting local mise config"
  mise trust >/dev/null 2>&1 || true
fi

# ── Bun ────────────────────────────────────────────────────────

if ask "bun (JS runtime, for LSPs)"; then
  echo "==> Installing bun"

  if ! command -v bun >/dev/null 2>&1; then
    curl -fsSL https://bun.sh/install | bash
  fi
fi

# ── Dotfiles ───────────────────────────────────────────────────

if ask "dotfiles (tmux, fish, git, mise configs)"; then
  echo "==> Installing dotfiles"

  if [ ! -d "$HOME/.dotfiles" ]; then
    git clone --bare "$REPO_URL" "$HOME/.dotfiles"
  fi

  dotfiles config status.showUntrackedFiles no

  if ! dotfiles checkout; then
    echo ""
    echo "WARNING: checkout conflicts detected."
    echo ""
    echo "Back up or remove conflicting files, then run:"
    echo ""
    echo "  git --git-dir=\$HOME/.dotfiles --work-tree=\$HOME checkout"
    echo ""

    exit 1
  fi
fi

# ── Environment ────────────────────────────────────────────────

if command -v mise >/dev/null 2>&1; then
  if ! grep -q "mise/shims" "$HOME/.profile" 2>/dev/null; then
    echo 'export PATH="$HOME/.local/share/mise/shims:$PATH"' >> "$HOME/.profile"
  fi
fi

# ── Mise tools ─────────────────────────────────────────────────

if command -v mise >/dev/null 2>&1; then
  if ask "mise tools (neovim, tmux, lazygit, bat, eza, fd, fzf, rg, zoxide, go, gh)"; then
    echo "==> Installing mise tools"
    mise install
  fi
fi

# ── Bun packages ───────────────────────────────────────────────

if command -v bun >/dev/null 2>&1; then
  if ask "JS/TS language servers"; then
    echo "==> Installing bun global packages"

    bun install -g \
      dockerfile-language-server-nodejs \
      vscode-langservers-extracted \
      typescript-language-server \
      yaml-language-server \
      bash-language-server || true
  fi
fi

# ── terraform-ls ───────────────────────────────────────────────

if ask "terraform-ls"; then
  echo "==> Installing terraform-ls"

  if ! command -v terraform-ls >/dev/null 2>&1; then
    require_cmd unzip

    if command -v python3 >/dev/null 2>&1; then
      LATEST="$(
        curl -sL https://api.github.com/repos/hashicorp/terraform-ls/releases/latest |
        python3 -c "import json,sys; print(json.load(sys.stdin)['tag_name'])"
      )"
    else
      LATEST="$(
        curl -sL https://api.github.com/repos/hashicorp/terraform-ls/releases/latest |
        grep tag_name |
        cut -d'"' -f4
      )"
    fi

    curl -fsSL \
      "https://releases.hashicorp.com/terraform-ls/${LATEST#v}/terraform-ls_${LATEST#v}_${OS_ALT}_${ARCH_ALT}.zip" \
      -o /tmp/tfls.zip

    unzip -o /tmp/tfls.zip terraform-ls -d "$HOME/.local/bin/"
    chmod +x "$HOME/.local/bin/terraform-ls"

    rm -f /tmp/tfls.zip
  fi
fi

# ── Lua Language Server ────────────────────────────────────────

if ask "lua-language-server"; then
  echo "==> Installing lua-language-server"

  if ! command -v lua-language-server >/dev/null 2>&1; then
    require_cmd tar

    LUALS_URL="$(
      curl -fsSL https://api.github.com/repos/LuaLS/lua-language-server/releases/latest |
      grep browser_download_url |
      grep "${ARCH_LS}.tar.gz" |
      cut -d '"' -f 4 |
      head -n1
    )"

    if [ -z "${LUALS_URL:-}" ]; then
      echo "ERROR: failed to detect lua-language-server download URL"
      exit 1
    fi

    curl -fsSL "$LUALS_URL" -o /tmp/luals.tar.gz

    rm -rf /tmp/luals
    mkdir -p /tmp/luals

    tar xzf /tmp/luals.tar.gz -C /tmp/luals

    install -m 755 \
      /tmp/luals/bin/lua-language-server \
      "$HOME/.local/bin/lua-language-server"

    rm -rf /tmp/luals /tmp/luals.tar.gz
  fi
fi

# ── Bun → Node Symlinks ────────────────────────────────────────

if command -v bun >/dev/null 2>&1; then
  echo "==> Symlinking bun as node/npm/npx"

  ln -sf "$(command -v bun)" "$HOME/.local/bin/node"
  ln -sf "$(command -v bun)" "$HOME/.local/bin/npm"
  ln -sf "$(command -v bun)" "$HOME/.local/bin/npx"
fi

# ── Neovim Config ──────────────────────────────────────────────

if ask "Neovim config"; then
  echo "==> Installing Neovim config"

  if [ ! -d "$HOME/.config/nvim/.git" ]; then
    git clone "$NVIM_REPO" "$HOME/.config/nvim"
    echo "  Run 'nvim' to install plugins"
  else
    echo "  ~/.config/nvim already exists, skipping"
  fi
fi

# ── SSH Config ──────────────────────────────────────────────────

if ask "SSH hardening (security and connection optimizations)"; then
  echo "==> Configuring SSH"

  mkdir -p "$HOME/.ssh" "$HOME/.ssh/controlmasters"
  chmod 700 "$HOME/.ssh"

  SSH_CONFIG="$HOME/.ssh/config"
  MARKER="# ── dotfiles: security & optimizations ──"

  if [ ! -f "$SSH_CONFIG" ]; then
    cat > "$SSH_CONFIG" << 'SSHEOF'
# ── Security ──────────────────────────────────────────
HostbasedAuthentication no
IgnoreRhosts yes
PermitLocalCommand no
StrictHostKeyChecking ask
HashKnownHosts yes
PubkeyAuthentication yes
PasswordAuthentication no
ChallengeResponseAuthentication no
ForwardAgent no
ForwardX11 no
LogLevel VERBOSE

# ── Performance ───────────────────────────────────────
GSSAPIAuthentication no
ConnectTimeout 10
ConnectionAttempts 3
TCPKeepAlive yes
ServerAliveInterval 60
ServerAliveCountMax 3

# ── Multiplexing ──────────────────────────────────────
ControlMaster auto
ControlPath ~/.ssh/controlmasters/%r@%h:%p
ControlPersist 10m

# ── Convenience ───────────────────────────────────────
AddKeysToAgent yes
SSHEOF
    chmod 600 "$SSH_CONFIG"
    echo "  Created $SSH_CONFIG with security defaults"

  elif ! grep -qF "$MARKER" "$SSH_CONFIG" 2>/dev/null; then
    chmod 600 "$SSH_CONFIG"

    {
      echo ""
      echo "$MARKER"
      echo "Host *"
    } >> "$SSH_CONFIG"

    for setting in \
      "HostbasedAuthentication no" \
      "IgnoreRhosts yes" \
      "PermitLocalCommand no" \
      "StrictHostKeyChecking ask" \
      "HashKnownHosts yes" \
      "PubkeyAuthentication yes" \
      "PasswordAuthentication no" \
      "ChallengeResponseAuthentication no" \
      "ForwardAgent no" \
      "ForwardX11 no" \
      "LogLevel VERBOSE" \
      "GSSAPIAuthentication no" \
      "ConnectTimeout 10" \
      "ConnectionAttempts 3" \
      "TCPKeepAlive yes" \
      "ServerAliveInterval 60" \
      "ServerAliveCountMax 3" \
      "ControlMaster auto" \
      "ControlPath ~/.ssh/controlmasters/%r@%h:%p" \
      "ControlPersist 10m" \
      "AddKeysToAgent yes"
    do
      key="${setting%% *}"
      if ! grep -qs "^[[:space:]]*${key}[[:space:]]" "$SSH_CONFIG"; then
        echo "  ${setting}" >> "$SSH_CONFIG"
      fi
    done

    echo "  Appended missing settings to $SSH_CONFIG"
  else
    echo "  SSH settings already applied, skipping"
  fi
fi

echo ""
echo "========================================"
echo "  Done!"
echo ""
echo "  Restart your shell or run:"
echo "    exec fish"
echo "========================================"
