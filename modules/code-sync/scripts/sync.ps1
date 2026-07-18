# sync.ps1 - diff-driven incremental LLM Wiki sync.
# Usage: powershell -File scripts\sync.ps1   (or bind it to a button/hotkey/cron)
# Requires: git, claude CLI on PATH. Run from anywhere; paths resolve from this script's location.

$ErrorActionPreference = "Stop"

$vault = Split-Path -Parent $PSScriptRoot
$statePath = Join-Path $vault "wiki-state.json"
$state = Get-Content $statePath -Raw | ConvertFrom-Json

$repo = $state.project_repo
if (-not [System.IO.Path]::IsPathRooted($repo)) {
    $repo = Join-Path $vault $repo
}
$repo = (Resolve-Path $repo).Path
$branch = $state.branch

Write-Host "Fetching origin..."
$fetchFailed = $false
try {
    git -C $repo fetch origin 2>&1 | Out-Null
} catch {
    $fetchFailed = $true
}
if ($fetchFailed) {
    Write-Host "Warning: 'git fetch' failed (network/credential issue?) - falling back to the locally-known origin/$branch ref. The diff below may be stale." -ForegroundColor Yellow
}

$head = (git -C $repo rev-parse "origin/$branch").Trim()

if ($null -eq $state.last_synced_sha) {
    Write-Host "last_synced_sha is null - run the Bootstrap workflow first (see CLAUDE.md). If Bootstrap already finished, set last_synced_sha to the SHA it finished at and re-run." -ForegroundColor Yellow
    exit 1
}

if ($head -eq $state.last_synced_sha) {
    Write-Host "Wiki already up to date at $head." -ForegroundColor Green
    exit 0
}

$range = "$($state.last_synced_sha)..$head"
$files = git -C $repo diff --name-only $range
Write-Host "`nChanges on origin/$branch ($range):" -ForegroundColor Cyan
git -C $repo log --oneline $range
Write-Host "`nFiles:"
$files | ForEach-Object { Write-Host "  $_" }

$prompt = @"
Run the Sync workflow defined in CLAUDE.md.

- Project repo: $repo
- Range: $range  (branch origin/$branch)
- Changed files:
$(($files | ForEach-Object { "  - $_" }) -join "`n")

Triage the changes (skip pure noise), update the affected wiki pages, update index.md, append a 'sync' entry to log.md, and finally set wiki-state.json last_synced_sha to $head.
"@

Set-Location $vault
claude -p $prompt --add-dir $repo --permission-mode acceptEdits

# Verify the agent advanced the state
$after = (Get-Content $statePath -Raw | ConvertFrom-Json).last_synced_sha
if ($after -eq $head) {
    Write-Host "`nSync complete: wiki now at $head" -ForegroundColor Green
} else {
    Write-Host "`nWarning: last_synced_sha is '$after', expected '$head'. Check the run output / log.md." -ForegroundColor Yellow
}
