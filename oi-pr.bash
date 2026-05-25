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

ai_text="$(opencode run --format json "$prompt" | jq -rs '[.[] | select(.type == "text") | .part.text] | join("")')"

generated="$(printf '%s' "$ai_text" | jq -er '.')"

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

if git rev-parse --verify "$branch_name" >/dev/null 2>&1; then
  echo "error: local branch already exists: $branch_name" >&2
  exit 1
fi

use_workmux="false"
if [ "${selection_key:-enter}" = "ctrl-y" ]; then
  use_workmux="true"
fi

git checkout -b "$branch_name"

default_branch="$(gh repo view --json defaultBranchRef --jq '.defaultBranchRef.name')"
if [ "$(git rev-list --count "${default_branch}..HEAD")" -eq 0 ]; then
  git commit --allow-empty -m "chore: start issue #${issue_number}"
fi

repo_name_with_owner="$(gh repo view --json nameWithOwner --jq '.nameWithOwner')"
head_sha="$(git rev-parse HEAD)"

gh api \
  --method POST \
  "repos/${repo_name_with_owner}/git/refs" \
  -f "ref=refs/heads/${branch_name}" \
  -f "sha=${head_sha}" \
  >/dev/null

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
