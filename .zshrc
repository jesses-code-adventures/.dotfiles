export DEFAULT_USER=$USER
export PS1="%1d %& # "
alias air="~/go/bin/air"
alias vim="nvim"
PROMPT="%F{magenta}%1d%f~$ "
export PATH=$PATH:"$HOME/.local/bin"
export PATH=$PATH:"$HOME/go/bin"
export PATH="$PATH:/Library/PostgreSQL/16/bin"

test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"
source ~/.iterm2_shell_integration.zsh

prompt_context() {
  if [[ "$USER" != "$DEFAULT_USER" || -n "$SSH_CLIENT" ]]; then
    prompt_segment black default "%(!.%{%F{yellow}%}.)$USER"
  fi
}

# treat tmux sessions as projects
p() {
    local script_name="$1"
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
            bash "$script_path"
        else
            echo "Script not found: $script_name"
        fi
    fi
}

if [ -f "./.zshrc_personal" ]; then
    source "./.zshrc_personal"
fi
