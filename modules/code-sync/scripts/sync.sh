#!/usr/bin/env bash
# sync.sh - diff-driven incremental LLM Wiki sync.
# Usage: ./scripts/sync.sh   (or bind it to a cron job)
# Requires: git, jq, claude CLI on PATH. Run from anywhere; paths resolve from this script's location.

set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
vault="$(dirname "$script_dir")"
state_path="$vault/wiki-state.json"

repo="$(jq -r '.project_repo' "$state_path")"
branch="$(jq -r '.branch' "$state_path")"
last_synced_sha="$(jq -r '.last_synced_sha' "$state_path")"

if [[ "$repo" != /* ]]; then
    repo="$vault/$repo"
fi
repo="$(cd "$repo" && pwd)"

echo "Fetching origin..."
if ! git -C "$repo" fetch origin 2>/dev/null; then
    echo "Warning: 'git fetch' failed (network/credential issue?) - falling back to the locally-known origin/$branch ref. The diff below may be stale." >&2
fi

head="$(git -C "$repo" rev-parse "origin/$branch")"

if [[ "$last_synced_sha" == "null" ]]; then
    echo "last_synced_sha is null - run the Bootstrap workflow first (see CLAUDE.md). If Bootstrap already finished, set last_synced_sha to the SHA it finished at and re-run." >&2
    exit 1
fi

if [[ "$head" == "$last_synced_sha" ]]; then
    echo "Wiki already up to date at $head."
    exit 0
fi

range="$last_synced_sha..$head"
files="$(git -C "$repo" diff --name-only "$range")"

echo ""
echo "Changes on origin/$branch ($range):"
git -C "$repo" log --oneline "$range"
echo ""
echo "Files:"
echo "$files" | sed 's/^/  /'

files_bulleted="$(echo "$files" | sed 's/^/  - /')"

prompt="Run the Sync workflow defined in CLAUDE.md.

- Project repo: $repo
- Range: $range  (branch origin/$branch)
- Changed files:
$files_bulleted

Triage the changes (skip pure noise), update the affected wiki pages, update index.md, append a 'sync' entry to log.md, and finally set wiki-state.json last_synced_sha to $head."

cd "$vault"
claude -p "$prompt" --add-dir "$repo" --permission-mode acceptEdits

after="$(jq -r '.last_synced_sha' "$state_path")"
if [[ "$after" == "$head" ]]; then
    echo ""
    echo "Sync complete: wiki now at $head"
else
    echo ""
    echo "Warning: last_synced_sha is '$after', expected '$head'. Check the run output / log.md." >&2
fi
