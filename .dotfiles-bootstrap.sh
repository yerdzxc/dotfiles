#!/usr/bin/env bash
set -euo pipefail

REPO_URL="https://github.com/yerdzxc/dotfiles.git"

# ── Prerequisites ──────────────────────────────────────────────
for cmd in git curl unzip tar; do
  if ! command -v "$cmd" &>/dev/null; then
    echo "ERROR: $cmd is required. Install it first: sudo apt install -y $cmd"
    exit 1
  fi
done

# Detect architecture
ARCH=$(uname -m)
case "$ARCH" in
  x86_64)  ARCH_ALT="amd64"; ARCH_LS="x64" ;;
  aarch64) ARCH_ALT="arm64"; ARCH_LS="arm64" ;;
  *)       echo "ERROR: unsupported architecture $ARCH"; exit 1 ;;
esac

export PATH="$HOME/.local/bin:$HOME/.bun/bin:$PATH"

# ── mise ────────────────────────────────────────────────────────
echo "==> Installing mise"
if ! command -v mise &>/dev/null; then
  curl -fsSL https://mise.jdx.dev/install.sh | sh
fi
eval "$(mise activate bash 2>/dev/null || echo '')"

# ── bun ─────────────────────────────────────────────────────────
echo "==> Installing bun"
if ! command -v bun &>/dev/null; then
  curl -fsSL https://bun.sh/install | bash
fi

# ── Dotfiles ────────────────────────────────────────────────────
echo "==> Cloning dotfiles"
if [ ! -d "$HOME/.dotfiles" ]; then
  git clone --bare "$REPO_URL" "$HOME/.dotfiles"
fi
alias dotfiles='git --git-dir=$HOME/.dotfiles --work-tree=$HOME'
dotfiles config status.showUntrackedFiles no
dotfiles checkout 2>&1 | grep -v "would be overwritten" || true
dotfiles config status.showUntrackedFiles no

# ── mise tools ──────────────────────────────────────────────────
echo "==> Installing mise tools"
mise install

# ── Bun packages ────────────────────────────────────────────────
echo "==> Installing bun global packages"
bun install -g dockerfile-language-server-nodejs \
  vscode-langservers-extracted \
  typescript-language-server \
  yaml-language-server \
  bash-language-server 2>/dev/null || true

# ── Terraform LS ────────────────────────────────────────────────
echo "==> Installing terraform-ls"
if ! command -v terraform-ls &>/dev/null; then
  LATEST=$(curl -sL https://api.github.com/repos/hashicorp/terraform-ls/releases/latest | python3 -c "import json,sys; print(json.load(sys.stdin)['tag_name'])")
  curl -sL "https://releases.hashicorp.com/terraform-ls/${LATEST#v}/terraform-ls_${LATEST#v}_linux_${ARCH_ALT}.zip" -o /tmp/tfls.zip
  unzip -o /tmp/tfls.zip terraform-ls -d "$HOME/.local/bin/" && rm /tmp/tfls.zip
fi

# ── Lua LS ──────────────────────────────────────────────────────
echo "==> Installing lua-language-server"
if ! command -v lua-language-server &>/dev/null; then
  curl -sL "https://github.com/LuaLS/lua-language-server/releases/latest/download/lua-language-server-linux-${ARCH_LS}.tar.gz" -o /tmp/luals.tar.gz
  tar xzf /tmp/luals.tar.gz -C /tmp
  install -m 755 /tmp/bin/lua-language-server "$HOME/.local/bin/"
  rm -rf /tmp/luals.tar.gz /tmp/bin
fi

# ── Bun → Node symlinks for Mason ──────────────────────────────
echo "==> Symlinking bun as node for Mason"
mkdir -p "$HOME/.local/bin"
ln -sf "$(command -v bun)" "$HOME/.local/bin/node"
ln -sf "$(command -v bun)" "$HOME/.local/bin/npm"
ln -sf "$(command -v bun)" "$HOME/.local/bin/npx"

echo "==> Done! Restart your shell or run: exec fish"
