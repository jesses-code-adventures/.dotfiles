# jesse's dotfiles

i use this repo to set up new macOS and Linux development machines. Windows is not supported.

## installation

Clone the repository recursively and run the platform installer:

_note: do not blindly install this on your own system. this is for fresh installs and contains my preferred defaults_

```bash
git clone --recurse-submodules https://github.com/jesses-code-adventures/.dotfiles ~/.dotfiles
chmod +x ~/.dotfiles/install
~/.dotfiles/install
```

The Linux installer expects Mise and the base build tools installed by the `dev-box` repository. Existing files replaced by symlinks are retained with a `.pre-dotfiles` suffix.

Git uses `jesse@soundsystems.dev` globally and `jesse@rapidpaylegal.com` for repositories under `/workspace/coding/rapid`. Private `lfsgroup` GitHub dependencies are fetched with the forwarded SSH key.

Run `aws-login` to check the Rapid, Sound Systems, and GiveTel sessions and start phone-friendly device authorization only for sessions that have expired. All three Rapid profiles share one `rapid` SSO session.

On the dev box, npm and Go caches are stored under `/workspace/cache` so package and build caches cannot fill the root volume.

## Rex / workmux

Use Rex instead of launching tmux. Workmux detects `REX_BLOCK` in Rex terminals;
inside tmux it still selects tmux. Don't export `WORKMUX_BACKEND` globally: this
keeps `wm`, `wmdb`, `oip`, and `op` working with either backend, including Linux.
The shared `config/workmux/config.yaml` keeps one session per worktree with
`nvim`, `bash`, `opencode`, and `dev` tabs on both backends.

### First-time switch

Rex support is merged upstream but **not in workmux v0.1.282**, the latest release
as of 2026-11-14. The installed v0.1.207 is also too old. Until a release includes
Rex, build the merged backend with Rust/Cargo installed:

```bash
rustup update stable # locked dependencies require Rust 1.95 or newer
cargo install --git https://github.com/raine/workmux \
  --rev 40de76fb1e49978f3caaa9b1da791be1bd0086b3 --locked \
  --root "$HOME/.local" --force
hash -r
command -v workmux # should be ~/.local/bin/workmux
```

On macOS, `~/.config` already links to this repo, including `rex/init.lua`.
In Rex Settings, enable **Remote Control** if you want workmux to switch the
visible session/tab automatically. This also permits other local CLI callers to
control the app; without it, select the created session manually.

```bash
rex config check
rex config reload
cd /path/to/project
wm list
wm add my-task
```

The Rex bindings mirror tmux: `Ctrl-Z` then `p` switches sessions, `s`/`v`
split panes, `h`/`j`/`k`/`l` move focus, `r` reloads config, and `Shift-W`
renames a tab. `Ctrl-H`/`Ctrl-L` switch tabs; `Ctrl-Z Ctrl-Z` sends `Ctrl-Z`.
`Ctrl-Z f` opens the project sessionizer picker in a temporary Projects tab.
The launcher uses Rex's native New Tab action for focus, then runs the picker
only after verifying that exactly one new tab is active in the calling session.
`Ctrl-Z Shift-L` jumps to the last session where you used `Ctrl-Z`, per Rex
client. Mouse-only visits aren't tracked, and config reload clears this history.
When the focused Rex terminal is running tmux, `Ctrl-Z`, `Ctrl-H`, and `Ctrl-L`
pass through to tmux instead of invoking Rex shortcuts.
`Ctrl-Z x` closes the focused Rex pane (and its tab if it is the last pane)
without a custom confirmation step.

### Back to tmux

Open your usual terminal and attach to tmux; no config edit or reinstall is
needed. An explicit per-command override is also available:

```bash
WORKMUX_BACKEND=tmux workmux list
```

Tmux config, plugins, sessionizer, and `p` session scripts are left intact.
The sessionizer's directory picker now uses tmux inside tmux and delegates to
`rex_sessionizer.bash` otherwise (requires `rex` and `jq`). Startup commands for
new Rex sessions come from the project's `.rex-sessionizer`, falling back to
`~/.rex-sessionizer`; `.tmux-sessionizer` is not run in Rex. Both installers
link the helper beside the original script in `~/.local/bin`.
Existing tmux sessions are not transferred to Rex: from the repository, use
`wm open <handle>` in Rex to open an existing worktree there. Keep the old
session until any running jobs finish; avoid running agents in both copies of
the same worktree. Changing backends does not copy or remove worktrees.
