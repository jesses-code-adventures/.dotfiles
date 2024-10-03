export EDITOR=vi
set -o vi
export DEFAULT_USER=$USER
export PS1="%1d %& # "
alias air="~/go/bin/air"
alias vim="nvim"
PROMPT="%F{magenta}%1d%f~$ "
export PATH=$PATH:"$HOME/.local/bin"
export PATH=$PATH:"$HOME/go/bin"
export PATH="$PATH:/Library/PostgreSQL/16/bin"
alias gc="git checkout"
alias gs="git status"
alias gp="git pull"
alias gb="git branch"
alias gm="git merge"
alias ghv='gh repo view -w'
alias ghpr='gh pr list'
alias gcm='git checkout main'
alias gmm='git merge main'
alias pipe='gh run list -L 5'
alias ciw='watch -n 10 pipe'

test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"
source ~/.iterm2_shell_integration.zsh

prompt_context() {
  if [[ "$USER" != "$DEFAULT_USER" || -n "$SSH_CLIENT" ]]; then
    prompt_segment black default "%(!.%{%F{yellow}%}.)$USER"
  fi
}

alias prs='git fetch --all && gh pr list --json number,createdAt,headRefName,author,title,url | jq -r ".[] | [.number, .createdAt, .headRefName, .title, .author.login, .url] | @csv" | sort -r | column -ts $"," | sed "s/\"//g" | fzf | awk "{printf \$3}" | xargs -I_ git checkout _'
        # /usr/local/bin/git
        # /usr/local/bin/gh
        # /usr/local/bin/jq
        # /usr/bin/sort
        # /usr/bin/column
        # /usr/local/opt/gnu-sed/libexec/gnubin/sed
        # /usr/local/bin/fzf
        # /usr/bin/awk
        # /usr/bin/xargs

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

if [ -f "./.zshrc_personal" ]; then
    source "./.zshrc_personal"
elif [ -f "$HOME/.dotfiles/zshrc_personal" ]; then
    source "$HOME/.dotfiles/zshrc_personal"
fi
