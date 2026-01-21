if [ -f ~/.bashrc ]; then
  source ~/.bashrc
fi
export PATH="/opt/homebrew/opt/postgresql@17/bin:$PATH"
. "$HOME/.cargo/env"
