#!/usr/bin/env bash

set -euo pipefail

ITERM_PROFILE="SSH"
TARGETS_FILE="${SSH_FZF_TARGETS_FILE:-$HOME/.dotfiles/ssh/targets.age}"
AGE_IDENTITY_FILE="${AGE_IDENTITY_FILE:-$HOME/.config/age/keys.txt}"

load_targets() {
  if ! command -v age >/dev/null 2>&1; then
    printf 'age is required to decrypt SSH targets\n' >&2
    return 1
  fi

  if [[ ! -f "$TARGETS_FILE" ]]; then
    printf 'SSH targets file not found: %s\n' "$TARGETS_FILE" >&2
    return 1
  fi

  if [[ ! -f "$AGE_IDENTITY_FILE" ]]; then
    printf 'age identity file not found: %s\n' "$AGE_IDENTITY_FILE" >&2
    return 1
  fi

  mapfile -t TARGETS < <(age -d -i "$AGE_IDENTITY_FILE" "$TARGETS_FILE")
}

ssh_in_iterm() {
  local profile="$1"
  local cmd="TMUX= $2"

  if [[ -n "${TMUX:-}" ]] && command -v osascript >/dev/null 2>&1; then
    osascript - "$profile" "$cmd" <<'APPLESCRIPT'
on run argv
    tell application "iTerm2"
        activate
        set newWindow to (create window with profile (item 1 of argv))
        tell current session of newWindow
            write text (item 2 of argv)
        end tell
    end tell
end run
APPLESCRIPT
  else
    eval "$cmd"
  fi
}

select_target() {
  local name target

  if ! command -v fzf >/dev/null 2>&1; then
    printf 'fzf is required for target selection\n' >&2
    return 1
  fi

  name=$(
    for target in "${TARGETS[@]}"; do
      printf '%s\n' "${target%%|*}"
    done | fzf --height=40% --layout=reverse --prompt='ssh> ' --no-bold
  )

  [[ -n "$name" ]] || return 1

  for target in "${TARGETS[@]}"; do
    if [[ "${target%%|*}" == "$name" ]]; then
      printf '%s\n' "${target#*|}"
      return 0
    fi
  done

  printf 'unknown target: %s\n' "$name" >&2
  return 1
}

main() {
  local cmd

  load_targets
  cmd="$(select_target)" || exit $?
  ssh_in_iterm "$ITERM_PROFILE" "$cmd"
}

main "$@"
