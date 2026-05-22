#!/usr/bin/env bash
set -eo pipefail

REPO_URL="https://github.com/yerdzxc/dotfiles.git"
NVIM_REPO="https://github.com/yerdzxc/nvim.git"
AUTO=0
[ "${1:-}" = "-y" ] && AUTO=1

ask() {
  [ "$AUTO" = 1 ] && return 0
  echo ""
  read -rp "  Install $1? [Y/n] " ans
  [ "${ans:-y}" = "y" ] || [ "${ans:-y}" = "Y" ]
}

# ── Prerequisites ──────────────────────────────────────────────
for cmd in git curl; do
  if ! command -v "$cmd" &>/dev/null; then
    echo "ERROR: $cmd is required. Install it first:"
    echo "  Linux:  sudo apt install -y $cmd"
    echo "  macOS:  xcode-select --install"
    exit 1
  fi
done

OS=$(uname -s)
ARCH=$(uname -m)

case "$OS-$ARCH" in
  Linux-x86_64)  OS_ALT="linux";  ARCH_ALT="amd64"; ARCH_LS="linux-x64"   ;;
  Linux-aarch64) OS_ALT="linux";  ARCH_ALT="arm64"; ARCH_LS="linux-arm64"  ;;
  Darwin-arm64)  OS_ALT="darwin"; ARCH_ALT="arm64"; ARCH_LS="darwin-arm64" ;;
  Darwin-x86_64) OS_ALT="darwin"; ARCH_ALT="amd64"; ARCH_LS="darwin-x64"  ;;
  *) echo "ERROR: unsupported $OS-$ARCH"; exit 1 ;;
esac

export PATH="$HOME/.local/bin:$HOME/.bun/bin:$PATH"

echo ""
echo "========================================"
echo "  dotfiles bootstrap"
echo "  https://github.com/yerdzxc/dotfiles"
echo "========================================"

# ── Mise ────────────────────────────────────────────────────────
if ask "mise (runtime manager)"; then
  echo "==> Installing mise"
  if ! command -v mise &>/dev/null; then
    curl -fsSL https://mise.jdx.dev/install.sh | sh
  fi
  eval "$(mise activate bash 2>/dev/null || echo '')"
fi

# ── Bun ─────────────────────────────────────────────────────────
if ask "bun (JS runtime, for LSPs)"; then
  echo "==> Installing bun"
  if ! command -v bun &>/dev/null; then
    curl -fsSL https://bun.sh/install | bash
  fi
fi

# ── Dotfiles ────────────────────────────────────────────────────
if ask "dotfiles (tmux, fish, git, mise configs)"; then
  echo "==> Cloning dotfiles"
  if [ ! -d "$HOME/.dotfiles" ]; then
    git clone --bare "$REPO_URL" "$HOME/.dotfiles"
  fi
  alias dotfiles='git --git-dir=$HOME/.dotfiles --work-tree=$HOME'
  dotfiles config status.showUntrackedFiles no
  dotfiles checkout 2>&1 | grep -v "would be overwritten" || true
  dotfiles config status.showUntrackedFiles no
fi

# ── Mise tools ──────────────────────────────────────────────────
if command -v mise &>/dev/null && ask "mise tools (neovim, tmux, lazygit, bat, eza, fd, fzf, rg, zoxide, go, gh)"; then
  echo "==> Installing mise tools"
  mise install
fi

# ── Bun packages (LSPs) ────────────────────────────────────────
if command -v bun &>/dev/null && ask "JS/TS LSPs (typescript, yaml, bash, docker, json)"; then
  echo "==> Installing bun global packages"
  bun install -g dockerfile-language-server-nodejs \
    vscode-langservers-extracted \
    typescript-language-server \
    yaml-language-server \
    bash-language-server 2>/dev/null || true
fi

# ── Native LSPs ────────────────────────────────────────────────
if ask "terraform-ls (HCL/OpenTofu)"; then
  echo "==> Installing terraform-ls"
  if ! command -v terraform-ls &>/dev/null; then
    if command -v python3 &>/dev/null; then
      LATEST=$(curl -sL https://api.github.com/repos/hashicorp/terraform-ls/releases/latest | python3 -c "import json,sys; print(json.load(sys.stdin)['tag_name'])")
    else
      LATEST=$(curl -sL https://api.github.com/repos/hashicorp/terraform-ls/releases/latest | grep tag_name | cut -d'"' -f4)
    fi
    curl -sL "https://releases.hashicorp.com/terraform-ls/${LATEST#v}/terraform-ls_${LATEST#v}_${OS_ALT}_${ARCH_ALT}.zip" -o /tmp/tfls.zip
    unzip -o /tmp/tfls.zip terraform-ls -d "$HOME/.local/bin/" 2>/dev/null && rm /tmp/tfls.zip
    chmod +x "$HOME/.local/bin/terraform-ls"
  fi
fi

if ask "lua-language-server (for Neovim config)"; then
  echo "==> Installing lua-language-server"
  if ! command -v lua-language-server &>/dev/null; then
    curl -sL "https://github.com/LuaLS/lua-language-server/releases/latest/download/lua-language-server-${ARCH_LS}.tar.gz" -o /tmp/luals.tar.gz
    tar xzf /tmp/luals.tar.gz -C /tmp 2>/dev/null
    install -m 755 /tmp/bin/lua-language-server "$HOME/.local/bin/" 2>/dev/null
    rm -rf /tmp/luals.tar.gz /tmp/bin
  fi
fi

# ── Bun → Node symlinks for Mason ──────────────────────────────
if command -v bun &>/dev/null; then
  echo "==> Symlinking bun as node for Mason"
  mkdir -p "$HOME/.local/bin"
  ln -sf "$(command -v bun)" "$HOME/.local/bin/node"
  ln -sf "$(command -v bun)" "$HOME/.local/bin/npm"
  ln -sf "$(command -v bun)" "$HOME/.local/bin/npx"
fi

# ── Neovim config ──────────────────────────────────────────────
if ask "Neovim config (clone github.com/yerdzxc/nvim)"; then
  echo "==> Cloning nvim config"
  if [ ! -d "$HOME/.config/nvim/.git" ]; then
    mkdir -p "$HOME/.config"
    git clone "$NVIM_REPO" "$HOME/.config/nvim"
    echo "  Run 'nvim' to let lazy.nvim install plugins"
  else
    echo "  ~/.config/nvim already exists, skipping"
  fi
fi

echo ""
echo "========================================"
echo "  Done! Restart your shell or run: exec fish"
echo "========================================"