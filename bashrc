export BASH_SILENCE_DEPRECATION_WARNING=1
export EDITOR=vi
set -o vi
export DEFAULT_USER=$USER
export PS1='\[\033[0;35m\]\W\[\033[00m\] '
alias air="~/go/bin/air"
alias vi="nvim"
export PATH=$PATH:"$HOME/.local/bin"
export PATH=$PATH:"$HOME/go/bin"
export PATH="$PATH:/Library/PostgreSQL/16/bin"
export PATH="$PATH:/opt/homebrew/bin"
export MANPAGER="sh -c 'col -bx | bat -l man -p'"
export PSQL_PAGER='pspg -X -b'
alias cat="bat"
alias ls="eza"
alias ll="eza --long"
alias tree="eza --tree"
alias gc="git checkout"
alias gs="git status"
alias gp="git pull"
alias gb="git branch"
alias gm="git merge"
alias ghv='gh repo view -w'
alias ghpr='gh pr list'
alias gmm='git fetch --all --prune && git merge origin/main'
alias pipe='gh run list -L 5'
alias ciw='watch -n 10 pipe'
test -e "${HOME}/.iterm2_shell_integration.bash" && source "${HOME}/.iterm2_shell_integration.bash"
alias prs='git fetch --all && gh pr list --json number,createdAt,headRefName,author,title,url | jq -r ".[] | [.number, .createdAt, .headRefName, .title, .author.login, .url] | @csv" | sort -r | column -ts $"," | sed "s/\"//g" | fzf | awk "{printf \$3}" | xargs -I_ git checkout _'
complete -W "\`if [ -f Makefile ]; then grep -oE '^[a-zA-Z0-9_-]+:([^=]|$)' Makefile | sed 's/[^a-zA-Z0-9_-]*$//'; elif [ -f makefile ]; then grep -oE '^[a-zA-Z0-9_-]+:([^=]|$)' makefile | sed 's/[^a-zA-Z0-9_-]*$//'; fi \`" make

## bash completion settings
bind 'set completion-ignore-case on'
bind 'set show-all-if-unmodified on'
[[ -r "/opt/homebrew/etc/profile.d/bash_completion.sh" ]] && . "/opt/homebrew/etc/profile.d/bash_completion.sh"

p() {
    local script_name="$1"
    shift
    if [ "$script_name" = "ls" ]; then
        local sessions_dir="$HOME/.config/tmux/sessions/"
        if [ -d "$sessions_dir" ]; then
            ls "$sessions_dir" | sed 's/\.bash$//'
        else
            echo "Sessions directory not found: $sessions_dir"
        fi
    elif [ "$script_name" = "cd" ]; then
        local sessions_dir="$HOME/.config/tmux/sessions/"
        if [ -d "$sessions_dir" ]; then
            cd "$sessions_dir"
        else
            echo "Sessions directory not found: $sessions_dir"
        fi
    else
        local script_path="$HOME/.config/tmux/sessions/$script_name.bash"
        if [ -f "$script_path" ]; then
            bash "$script_path" "$@"
        else
            echo "Script not found: $script_name"
        fi
    fi
}

vcom() {
    if [ "$(pwd)" != "$HOME/.config/nvim" ]; then
      echo "Script must be run from ~/.config/nvim"
      return
    fi
    commit_msg="${1:-nvim commit}"
    git add -A
    git commit -m "$commit_msg"
    cd ~/.dotfiles || return
    git reset
    git add config/nvim
    git commit -m "nvim sha"
    cd ~/.config/nvim || return
}

if [ -f "./.bashrc_personal" ]; then
    source "./.bashrc_personal"
elif [ -f "$HOME/.dotfiles/bashrc_personal" ]; then
    source "$HOME/.dotfiles/bashrc_personal"
fi

eval "$(starship init bash)"
