if status is-interactive
    ~/.local/bin/mise activate fish | source
    zoxide init fish | source

    # abbreviations
    abbr -a vim nvim
    abbr -a g git
    abbr -a ga 'git add'
    abbr -a gc 'git commit -m'
    abbr -a gp 'git push'
    abbr -a gs 'git status'
    abbr -a gd 'git diff'
    abbr -a gl 'git log --oneline --graph'
    abbr -a gco 'git checkout'
    abbr -a gb 'git branch'
    abbr -a lg lazygit
    abbr -a nv nvim
    abbr -a .. 'cd ..'
    abbr -a ... 'cd ../..'
    abbr -a .... 'cd ../../..'
    abbr -a so 'source ~/.config/fish/config.fish'
    abbr -a ll 'eza -l --icons'
    abbr -a la 'eza -la --icons'
    abbr -a lt 'eza -T --icons'
    abbr -a ls eza
    abbr -a cat bat
    abbr -a dotfiles 'git --git-dir=$HOME/.dotfiles --work-tree=$HOME'
end

set -gx EDITOR nvim
set -gx VISUAL nvim
set -U fish_greeting
