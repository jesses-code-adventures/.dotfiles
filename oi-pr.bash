#!/usr/bin/env bash
set -euo pipefail

for cmd in gh jq fzf opencode git workmux; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "error: required command not found: $cmd" >&2
    exit 1
  fi
done

issues_json="$(gh issue list --state open --search "-linked:pr no:assignee" --limit 100 --json number,title,url,body)"

if [ "$(printf '%s' "$issues_json" | jq 'length')" -eq 0 ]; then
  echo "No open unassigned issues found."
  exit 0
fi

selection_raw="$({
  printf '%s' "$issues_json" | jq -r '.[] | "#\(.number)\t\(.title)\t\(.url)"'
} | fzf --height=80% --layout=reverse --border --prompt="Issue > " --header="Enter: local branch | Ctrl-Y: workmux" --expect=enter,ctrl-y)"

selection_key="$(printf '%s\n' "$selection_raw" | sed -n '1p')"
selection="$(printf '%s\n' "$selection_raw" | sed -n '2p')"

if [ -z "${selection:-}" ]; then
  echo "No issue selected."
  exit 0
fi

issue_number="$(printf '%s' "$selection" | cut -f1 | tr -d '#')"
issue_title="$(printf '%s' "$selection" | cut -f2)"
issue_url="$(printf '%s' "$selection" | cut -f3)"
issue_body="$(printf '%s' "$issues_json" | jq -r --argjson n "$issue_number" '.[] | select(.number == $n) | .body')"

current_branch="$(git rev-parse --abbrev-ref HEAD)"

prompt="You are generating git and pull request metadata for a GitHub issue.
Return ONLY valid JSON with exactly these string fields:
- branch_name
- pr_title
- pr_body

Rules:
- branch_name: lowercase kebab-case, natural phrase, max 60 chars
- branch_name must NOT include numbers or the issue number
- pr_title: concise and actionable, do NOT include the issue number
- pr_body: short descriptive markdown text with no headings or subheadings
- pr_body must end with: Closes #${issue_number}

Issue:
- Number: ${issue_number}
- Title: ${issue_title}
- URL: ${issue_url}
- Current branch: ${current_branch}
- Body:
${issue_body}
"

ai_text="$(opencode run --format json "$prompt" </dev/null | jq -rs '[.[] | select(.type == "text") | .part.text] | join("")')"

# Some models wrap JSON in markdown code fences or add preamble text.
# Extract the first {...} block by finding the outermost braces.
ai_json="$(printf '%s' "$ai_text" | python3 -c "
import sys, re
text = sys.stdin.read()
# Find the first { and its matching }
start = text.find('{')
if start == -1:
    sys.exit(1)
depth = 0
for i, c in enumerate(text[start:], start):
    if c == '{': depth += 1
    elif c == '}':
        depth -= 1
        if depth == 0:
            print(text[start:i+1])
            sys.exit(0)
sys.exit(1)
")" || {
  echo "error: AI response contained no JSON object. Raw output:" >&2
  printf '%s\n' "$ai_text" >&2
  exit 1
}

generated="$(printf '%s' "$ai_json" | jq -er '.')" || {
  echo "error: AI response could not be parsed as JSON. Raw output:" >&2
  printf '%s\n' "$ai_text" >&2
  exit 1
}

branch_name="$(printf '%s' "$generated" | jq -r '.branch_name')"
pr_title="$(printf '%s' "$generated" | jq -r '.pr_title')"
pr_body="$(printf '%s' "$generated" | jq -r '.pr_body')"

if [ -z "$branch_name" ] || [ "$branch_name" = "null" ]; then
  echo "error: AI returned empty branch_name" >&2
  exit 1
fi

if [[ "$branch_name" =~ [0-9] ]]; then
  echo "error: AI returned invalid branch_name containing digits: $branch_name" >&2
  exit 1
fi

repo_name_with_owner="$(gh repo view --json nameWithOwner --jq '.nameWithOwner')"
branch_base="$branch_name"

branch_suffix() {
  local n="$1"
  local chars="abcdefghijklmnopqrstuvwxyz"
  local suffix=""

  while [ "$n" -gt 0 ]; do
    n=$((n - 1))
    suffix="${chars:$((n % 26)):1}${suffix}"
    n=$((n / 26))
  done

  printf '%s' "$suffix"
}

branch_exists() {
  local candidate="$1"

  if git show-ref --verify --quiet "refs/heads/${candidate}"; then
    return 0
  fi

  if gh api "repos/${repo_name_with_owner}/git/ref/heads/${candidate}" >/dev/null 2>&1; then
    return 0
  fi

  return 1
}

suffix_index=0
while branch_exists "$branch_name"; do
  suffix_index=$((suffix_index + 1))
  branch_name="${branch_base}-$(branch_suffix "$suffix_index")"
done

use_workmux="false"
if [ "${selection_key:-enter}" = "ctrl-y" ]; then
  use_workmux="true"
fi

git checkout -b "$branch_name"

default_branch="$(gh repo view --json defaultBranchRef --jq '.defaultBranchRef.name')"
if [ "$(git rev-list --count "${default_branch}..HEAD")" -eq 0 ]; then
  default_ref="$(gh api "repos/${repo_name_with_owner}/git/ref/heads/${default_branch}")"
  default_sha="$(printf '%s' "$default_ref" | jq -r '.object.sha')"
  default_commit="$(gh api "repos/${repo_name_with_owner}/git/commits/${default_sha}")"
  default_tree_sha="$(printf '%s' "$default_commit" | jq -r '.tree.sha')"
  remote_start_sha="$(gh api \
    --method POST \
    "repos/${repo_name_with_owner}/git/commits" \
    -f "message=chore: start issue #${issue_number}" \
    -f "tree=${default_tree_sha}" \
    -F "parents[]=${default_sha}" \
    --jq '.sha')"
  gh api \
    --method POST \
    "repos/${repo_name_with_owner}/git/refs" \
    -f "ref=refs/heads/${branch_name}" \
    -f "sha=${remote_start_sha}" \
    >/dev/null
  git fetch origin "$branch_name"
  git reset --soft FETCH_HEAD
else
  head_sha="$(git rev-parse HEAD)"
  gh api \
    --method POST \
    "repos/${repo_name_with_owner}/git/refs" \
    -f "ref=refs/heads/${branch_name}" \
    -f "sha=${head_sha}" \
    >/dev/null
fi

tmp_body_file="$(mktemp)"
trap 'rm -f "$tmp_body_file"' EXIT
printf '%s\n' "$pr_body" > "$tmp_body_file"

gh issue edit "$issue_number" --add-assignee "@me"

pr_url="$(gh -R "$repo_name_with_owner" pr create --title "$pr_title" --body-file "$tmp_body_file" --assignee "@me" --head "$branch_name")"

if [ "$use_workmux" = "true" ]; then
  git checkout "$current_branch"
  workmux add "$branch_name" --open-if-exists
fi

git push -u origin "$branch_name"

echo "Created branch: $branch_name"
echo "Created PR: $pr_url"
echo "Issue assigned: #$issue_number"
