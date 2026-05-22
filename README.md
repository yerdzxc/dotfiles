# dotfiles

Managed via a [bare git repo](https://www.atlassian.com/git/tutorials/dotfiles) with `--work-tree=$HOME`.

## What's tracked

| File | Purpose |
|---|---|
| `.tmux.conf` | tmux configuration |
| `.config/fish/config.fish` | Fish shell config + abbreviations |
| `.config/mise/config.toml` | Mise tool versions |
| `.gitconfig` | Git configuration |
| `.dotfiles-bootstrap.sh` | Bootstrap script for new machines |

Also tracked separately:
- [Neovim config](https://github.com/yerdzxc/nvim) (NvChad-based, independent repo at `~/.config/nvim`)

> **Security:** Only non-sensitive configs are tracked. Before adding any file, verify it contains no tokens, keys, or personal data. Secrets belong in environment variables or password managers, not dotfiles.

## Usage

```bash
# Daily use — add/commit/push new configs
dotfiles add .config/some-file
dotfiles commit -m "add some-file"
dotfiles push

# See what's tracked
dotfiles ls-files
```

## Bootstrap a new machine

Works on **Linux** (x86_64/arm64) and **macOS** (Apple Silicon/Intel).

Interactive — prompts for each component:

```bash
curl -fsSL https://raw.githubusercontent.com/yerdzxc/dotfiles/master/.dotfiles-bootstrap.sh | bash
```

Non-interactive (installs everything):

```bash
curl -fsSL https://raw.githubusercontent.com/yerdzxc/dotfiles/master/.dotfiles-bootstrap.sh | bash -s -- -y
```

## Tools installed

Managed by **mise**: neovim, tmux, lazygit, bat, eza, fd, fzf, ripgrep, zoxide, go, gh, tree-sitter, aws

Installed via **bun** (global): typescript-language-server, yaml-language-server, bash-language-server, dockerfile-language-server-nodejs, vscode-langservers-extracted

Native binaries: terraform-ls, lua-language-server
