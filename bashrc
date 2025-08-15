export BASH_SILENCE_DEPRECATION_WARNING=1
export EDITOR=nvim
set -o vi
export DEFAULT_USER=$USER
export PS1='\[\033[0;35m\]\W\[\033[00m\] '
alias air="~/go/bin/air"
alias vi="nvim"
export PATH=$PATH:"$HOME/.local/bin"
export PATH=$PATH:"$HOME/.config/wezterm"
export PATH=$PATH:"$HOME/go/bin"
export PATH="$PATH:/Library/PostgreSQL/16/bin"
export PATH="$PATH:/opt/homebrew/bin"
export npm_config_prefix="$HOME/.local"
# export MANPAGER="sh -c 'col -bx | bat -l man -p'"
export MANPAGER="nvim +Man!"
export PSQL_PAGER='pspg -X -b'
export HOMEBREW_NO_AUTO_UPDATE=1
alias vid="$HOME/.local/bin/vid-dl.bash"
alias cat="bat"
alias ls="eza"
alias ll="eza --long"
alias tree="eza --tree"
alias gc="git checkout"
alias gs="git status"
alias gp="git pull"
alias gb="git branch"
alias gbc="git branch --merged | grep -v '\*\|main\|master' | xargs -n 1 git branch -d"
alias gm="git merge"
alias ghv='gh repo view -w'
alias ghpr='gh pr list'
alias gl='git --no-pager log --oneline --graph --decorate --all -n 10'
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

qpr() {
    if [ -z "$1" ]; then
        echo "error: commit message cannot be empty"
        exit 1
    fi
    git add .
    git commit -m "$1"
    current_branch=$(git rev-parse --abbrev-ref HEAD)
    if git rev-parse --abbrev-ref --symbolic-full-name "@{u}" 2>/dev/null; then
        git push
    else
        if [ -z "$current_branch" ]; then
            echo "error: trying to create a remote branch, but couldn't find a current branch name"
        fi
        git push -u origin "$current_branch"
    fi
    gh pr create -t "$1" --body ""
}

qp() {
    if [ -z "$1" ]; then
        echo "error: commit message cannot be empty"
        exit 1
    fi
    git add .
    git commit -m "$1"
    current_branch=$(git rev-parse --abbrev-ref HEAD)
    if git rev-parse --abbrev-ref --symbolic-full-name "@{u}" 2>/dev/null; then
        git push
    else
        if [ -z "$current_branch" ]; then
            echo "error: trying to create a remote branch, but couldn't find a current branch name"
        fi
        git push -u origin "$current_branch"
    fi
}

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

# opencode
export PATH=/Users/jessewilliams/.opencode/bin:$PATH

eval "$(starship init bash)"

# Turso
export PATH="$PATH:$HOME/.turso"
