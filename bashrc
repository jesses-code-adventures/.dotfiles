export BASH_SILENCE_DEPRECATION_WARNING=1
export EDITOR=vi
set -o vi
export DEFAULT_USER=$USER
export PS1='\[\033[0;35m\]\W\[\033[00m\] '
alias air="~/go/bin/air"
alias vi="nvim"
alias vim="nvim"
export PATH=$PATH:"$HOME/.local/bin"
export PATH=$PATH:"$HOME/go/bin"
export PATH="$PATH:/Library/PostgreSQL/16/bin"
export PATH="$PATH:/opt/homebrew/bin"
alias gc="git checkout"
alias gs="git status"
alias gp="git pull"
alias gb="git branch"
alias gm="git merge"
alias ghv='gh repo view -w'
alias ghpr='gh pr list'
alias gcm='git fetch --all --prune && git merge origin/main'
alias gmm='git merge main'
alias pipe='gh run list -L 5'
alias ciw='watch -n 10 pipe'
test -e "${HOME}/.iterm2_shell_integration.bash" && source "${HOME}/.iterm2_shell_integration.bash"
alias prs='git fetch --all && gh pr list --json number,createdAt,headRefName,author,title,url | jq -r ".[] | [.number, .createdAt, .headRefName, .title, .author.login, .url] | @csv" | sort -r | column -ts $"," | sed "s/\"//g" | fzf | awk "{printf \$3}" | xargs -I_ git checkout _'
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
if [ -f "./.bashrc_personal" ]; then
    source "./.bashrc_personal"
elif [ -f "$HOME/.dotfiles/bashrc_personal" ]; then
    source "$HOME/.dotfiles/bashrc_personal"
fi
