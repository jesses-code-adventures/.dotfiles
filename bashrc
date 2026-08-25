export BASH_SILENCE_DEPRECATION_WARNING=1
export EDITOR=nvim
export PATH="/opt/homebrew/opt/go@1.25/bin:$PATH"
set -o vi
# export DEFAULT_USER=$USER
export PS1='\[\033[0;35m\]\W\[\033[00m\] '
alias air="~/go/bin/air"
alias vi="nvim"
export PATH=$PATH:"$HOME/.local/bin"
export PATH=$PATH:"$HOME/.config/wezterm"
export PATH=$PATH:"$HOME/go/bin"
export PATH="$PATH:/opt/nvim-linux-x86_64/bin"
export PATH="$PATH:/Library/PostgreSQL/16/bin"
export PATH="$PATH:/opt/homebrew/bin"
# export MANPAGER="sh -c 'col -bx | bat -l man -p'"
export MANPAGER="nvim +Man!"
export PSQL_PAGER='pspg -X -b'
export HOMEBREW_NO_AUTO_UPDATE=1
export ANDROID_HOME="$HOME/Library/Android/sdk"
export PATH="$PATH:$ANDROID_HOME/platform-tools"
export PATH="$PATH:$ANDROID_HOME/emulator"
export PATH="$PATH:$HOME/.bun/bin"
alias vid="$HOME/.local/bin/vid-dl.bash"
alias cat="bat"
alias wm="workmux"
alias wmdb="workmux dashboard"
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
alias oi='gh issue list --state open --search "-linked:pr no:assignee"'
alias oip='bash "$HOME/.dotfiles/oi-pr.bash"'
alias op='bash "$HOME/.dotfiles/oi-pr-existing.bash"'
alias pipe='gh run list -L 5'
alias ciw='watch -n 10 pipe'
alias rp-login='aws sso login --sso-session rapid --use-device-code'

aws-login() {
    local session profile
    while read -r session profile; do
        if AWS_PROFILE="$profile" aws sts get-caller-identity >/dev/null 2>&1; then
            printf '%s: already authenticated\n' "$session"
            continue
        fi
        printf '%s: authentication required\n' "$session"
        aws sso login --sso-session "$session" --use-device-code || return
    done <<'EOF'
rapid rp-sandbox
sound-systems sound-systems
givetel givetel
EOF
}
export OPENCODE_AUTH_PATH="$HOME/.local/share/opencode/auth.json"
alias ssh-in='./ssh-fzf.bash'
if fzf_bash=$(fzf --bash 2>/dev/null); then
  eval "$fzf_bash"
elif [ -f /usr/share/doc/fzf/examples/key-bindings.bash ]; then
  source /usr/share/doc/fzf/examples/key-bindings.bash
fi
if command -v opencode2 >/dev/null 2>&1; then
  alias opencode="opencode2"
fi

test -e "${HOME}/.iterm2_shell_integration.bash" && source "${HOME}/.iterm2_shell_integration.bash"
alias prs='git fetch --all && gh pr list --json number,createdAt,headRefName,author,title,url | jq -r ".[] | [.number, .createdAt, .headRefName, .title, .author.login, .url] | @csv" | sort -r | column -ts $"," | sed "s/\"//g" | fzf | awk "{printf \$3}" | xargs -I_ git checkout _'
complete -W "\`if [ -f Makefile ]; then grep -oE '^[a-zA-Z0-9_-]+:([^=]|$)' Makefile | sed 's/[^a-zA-Z0-9_-]*$//'; elif [ -f makefile ]; then grep -oE '^[a-zA-Z0-9_-]+:([^=]|$)' makefile | sed 's/[^a-zA-Z0-9_-]*$//'; fi \`" make
unset npm_config_prefix

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

if [ -f "/opt/homebrew/etc/profile.d/z.sh" ]; then
	. /opt/homebrew/etc/profile.d/z.sh
fi

# opencode
export PATH="$HOME/.opencode/bin:$PATH"
alias oc='opencode'

if command -v starship >/dev/null 2>&1; then
  eval "$(starship init bash)"
fi

# Turso
export PATH="$PATH:$HOME/.turso"

export PATH="$HOME/.pyenv/bin:$PATH"
if command -v pyenv 1>/dev/null 2>&1; then
  eval "$(pyenv init -)"
fi

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

export PATH="/opt/homebrew/opt/postgresql@17/bin:$PATH"
if [ -f "$HOME/.cargo/env" ]; then
  . "$HOME/.cargo/env"
fi

# dev-box-agent-forwarding
if [ -S "$HOME/.ssh/agent.sock" ]; then
  export SSH_AUTH_SOCK="$HOME/.ssh/agent.sock"
fi
