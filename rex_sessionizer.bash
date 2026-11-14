#!/usr/bin/env bash
set -euo pipefail

if [[ ${1:-} == --open-picker ]]; then
    [[ $# -eq 3 ]] || { echo 'Usage: rex_sessionizer.bash --open-picker <session> <client>' >&2; exit 1; }
    # Rex's macOS server doesn't inherit the terminal's PATH.
    rex_cli=$(command -v rex || printf '%s' "$HOME/Library/Application Support/com.superlogical.rex/RexServer/Versions/Current/Rex Server.app/Contents/MacOS/rex")
    exec "$rex_cli" -C "$3" do -s "$2" -e '
        local window, err = rex.session.new_window{
            window_label = "Projects",
            layout = rex.layout.block{
                flavor = "com.superlogical.terminal.shell",
                options = { command = { "bash", os.getenv("HOME") .. "/.dotfiles/tmux_sessionizer.bash" } },
            },
        }
        assert(window, err)
        rex.client.queue("session.select", { session_id = rex.session_id, window_id = window.window_id })
    '
fi

if [[ $# -ne 1 || ! -d $1 ]]; then
    echo 'Usage: rex_sessionizer.bash <existing-directory>' >&2
    exit 1
fi
for cmd in rex jq; do
    command -v "$cmd" >/dev/null || { echo "$cmd is required for Rex sessions" >&2; exit 1; }
done

selected=$(cd -- "$1" && pwd)
name=$(basename "$selected" | tr . _)
sessions=$(rex ls --json)
session_id=$(jq -er --arg name "$name" '
    [.sessions[] | select(.label == $name) | .session_id] |
    if length > 1 then error("Multiple Rex sessions have this name")
    else .[0] // "" end
' <<< "$sessions")

if [[ -z $session_id ]]; then
    startup="$selected/.rex-sessionizer"
    [[ -f $startup ]] || startup="$HOME/.rex-sessionizer"
    if [[ -f $startup ]]; then
        created=$(rex new "$name" -c "$selected" --json -- bash --login -c \
            'source "$1"; exec bash --login' bash "$startup")
    else
        created=$(rex new "$name" -c "$selected" --json)
    fi
    session_id=$(jq -er '.session_id | select(type == "string" and length > 0)' <<< "$created")
fi

if ! rex do session.select "session_id=$session_id"; then
    echo "Session '$name' is ready ($session_id). Select it in Rex, or enable Remote Control in Rex Settings." >&2
    exit 1
fi
