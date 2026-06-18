#!/usr/bin/env bash
set -euo pipefail

for cmd in gh jq fzf git workmux; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "error: required command not found: $cmd" >&2
    exit 1
  fi
done

prs_json="$(gh pr list --state open --limit 100 --json number,title,url,headRefName,author)"

if [ "$(printf '%s' "$prs_json" | jq 'length')" -eq 0 ]; then
  echo "No open PRs found."
  exit 0
fi

selection_raw="$({
  printf '%s' "$prs_json" | jq -r '.[] | "#\(.number)\t\(.title)\t\(.author.login)\t\(.headRefName)\t\(.url)"'
} | fzf --height=80% --layout=reverse --border --prompt="PR > " --header="Enter: local checkout | Ctrl-Y: workmux" --expect=enter,ctrl-y)"

selection_key="$(printf '%s\n' "$selection_raw" | sed -n '1p')"
selection="$(printf '%s\n' "$selection_raw" | sed -n '2p')"

if [ -z "${selection:-}" ]; then
  echo "No PR selected."
  exit 0
fi

pr_number="$(printf '%s' "$selection" | cut -f1 | tr -d '#')"
pr_branch="$(printf '%s' "$selection" | cut -f4)"
current_branch="$(git rev-parse --abbrev-ref HEAD)"

if [ -z "$pr_number" ] || [ -z "$pr_branch" ]; then
  echo "error: could not parse selected PR" >&2
  exit 1
fi

gh pr checkout "$pr_number"

if [ "${selection_key:-enter}" = "ctrl-y" ]; then
  git checkout "$current_branch"
  workmux add "$pr_branch" --open-if-exists
fi

echo "Opened PR #${pr_number}: ${pr_branch}"
