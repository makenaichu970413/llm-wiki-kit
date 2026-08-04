# dashboard.ps1 - compute vault stats from disk and render wiki/dashboard.html.
# Usage: powershell -File scripts\dashboard.ps1   (or bind it to a button/hotkey/cron)
# Requires: git (only used if wiki-state.json / code-sync is present). Run from anywhere;
# paths resolve from this script's location. Read-only: never writes to log.md/index.md.

$ErrorActionPreference = "Stop"

$vault = Split-Path -Parent $PSScriptRoot
$wikiDir = Join-Path $vault "wiki"
$statePath = Join-Path $vault "wiki-state.json"
$templatePath = Join-Path $vault "scripts\dashboard.template.html"
$outPath = Join-Path $wikiDir "dashboard.html"

function HtmlEscape([string]$s) {
    if ($null -eq $s) { return "" }
    return $s -replace '&', '&amp;' -replace '<', '&lt;' -replace '>', '&gt;'
}

function JsonEscape([string]$s) {
    if ($null -eq $s) { return "" }
    return $s -replace '\\', '\\' -replace '"', '\"'
}

# --- Project name (best-effort: from CLAUDE.md's title line, else the folder name) ---
$projectName = Split-Path -Leaf $vault
$claudeMdPath = Join-Path $vault "CLAUDE.md"
if (Test-Path $claudeMdPath) {
    $titleMatch = Select-String -Path $claudeMdPath -Pattern '^# (.+?) — LLM Wiki Schema' | Select-Object -First 1
    if ($titleMatch) { $projectName = $titleMatch.Matches[0].Groups[1].Value }
}

# --- Installed modules (detected by presence of marker files) ---
$installedModules = @("dashboard")
$isCodeSync = Test-Path $statePath
if ($isCodeSync) { $installedModules = @("code-sync") + $installedModules }
$isDecisions = Test-Path (Join-Path $wikiDir "decisions") -PathType Container
if ($isDecisions) { $installedModules += "decisions" }
$isRoadmap = Test-Path (Join-Path $wikiDir "plan.md") -PathType Leaf
if ($isRoadmap) { $installedModules += "roadmap" }

# --- Log stats ---
$logPath = Join-Path $wikiDir "log.md"
$opCounts = [ordered]@{}
$archivedCount = 0
$entries = @()   # each: date, op, subject, archived (bool)
$querySubjects = @()
$answerSubjects = New-Object System.Collections.Generic.HashSet[string]

if (Test-Path $logPath) {
    $logLines = Get-Content -Path $logPath -Encoding UTF8
    foreach ($line in $logLines) {
        if ($line -match '^## \[(\d{4}-\d{2}-\d{2})\] (\S+) \| (.*)$') {
            $date = $matches[1]
            $op = $matches[2]
            $subject = $matches[3]
            $archived = $false
            if ($subject -match '^(.*?)\s+—\s+⚠️ Archived \d{4}-\d{2}-\d{2}\s*$') {
                $archived = $true
                $subject = $matches[1]
                $archivedCount++
            }
            if (-not $opCounts.Contains($op)) { $opCounts[$op] = 0 }
            $opCounts[$op]++
            $entries += [PSCustomObject]@{ Date = $date; Op = $op; Subject = $subject; Archived = $archived }

            $normalized = $subject.Trim().Trim('"')
            if ($op -eq "query") { $querySubjects += $normalized }
            if ($op -eq "answer") { [void]$answerSubjects.Add($normalized.ToLowerInvariant()) }
        }
    }
}

$matchedAnswers = 0
foreach ($q in $querySubjects) {
    if ($answerSubjects.Contains($q.ToLowerInvariant())) { $matchedAnswers++ }
}
$conversionRatio = "$matchedAnswers/$($querySubjects.Count)"

$recentEntries = @($entries | Select-Object -Last 10)
[array]::Reverse($recentEntries)

# --- Health check: wikilinks, red links, orphans, superseded ---
$mdFiles = @()
if (Test-Path $wikiDir) { $mdFiles = @(Get-ChildItem -Path $wikiDir -Recurse -Filter *.md | Sort-Object -Property FullName) }

$pageNames = New-Object System.Collections.Generic.HashSet[string]
$pageInfo = [ordered]@{}   # normalized id -> @{ Label; Group }, for the knowledge-graph nodes
foreach ($f in $mdFiles) {
    $id = [System.IO.Path]::GetFileNameWithoutExtension($f.Name).ToLowerInvariant()
    [void]$pageNames.Add($id)
    if (-not $pageInfo.Contains($id)) {
        $rel = $f.FullName.Substring($wikiDir.Length).TrimStart('\', '/')
        $group = "root"
        $slashIdx = $rel.IndexOfAny(@('\', '/'))
        if ($slashIdx -ge 0) { $group = $rel.Substring(0, $slashIdx) }
        $pageInfo[$id] = [PSCustomObject]@{ Label = [System.IO.Path]::GetFileNameWithoutExtension($f.Name); Group = $group }
    }
}

$linkMentions = [ordered]@{}
$supersededCount = 0
$edgeSet = New-Object System.Collections.Generic.HashSet[string]
$graphEdges = @()
foreach ($f in $mdFiles) {
    $sourceId = [System.IO.Path]::GetFileNameWithoutExtension($f.Name).ToLowerInvariant()
    $content = Get-Content -Path $f.FullName -Raw -Encoding UTF8
    $supersededCount += ([regex]::Matches($content, '⚠️ Superseded')).Count
    foreach ($m in [regex]::Matches($content, '\[\[([^\]|#]+)')) {
        $target = $m.Groups[1].Value.Trim().ToLowerInvariant()
        if (-not $linkMentions.Contains($target)) { $linkMentions[$target] = 0 }
        $linkMentions[$target]++

        if ($target -ne $sourceId -and $pageNames.Contains($target)) {
            $pairKey = if ([string]::CompareOrdinal($sourceId, $target) -lt 0) { "$sourceId|$target" } else { "$target|$sourceId" }
            if ($edgeSet.Add($pairKey)) {
                $pairParts = $pairKey -split '\|', 2
                $graphEdges += [PSCustomObject]@{ Source = $pairParts[0]; Target = $pairParts[1] }
            }
        }
    }
}

$excludedFromOrphans = @("overview", "index", "log", "question")
$redLinks = @()
foreach ($target in $linkMentions.Keys) {
    if (-not $pageNames.Contains($target)) {
        $redLinks += [PSCustomObject]@{ Target = $target; Count = $linkMentions[$target] }
    }
}
$redLinks = @($redLinks | Sort-Object -Property Count -Descending)

$orphans = @()
foreach ($name in $pageNames) {
    if ($excludedFromOrphans -contains $name) { continue }
    $mentions = 0
    if ($linkMentions.Contains($name)) { $mentions = $linkMentions[$name] }
    if ($mentions -eq 0) { $orphans += $name }
}
$orphans = @($orphans | Sort-Object)

$overdueRedLinkCount = @($redLinks | Where-Object { $_.Count -ge 3 }).Count

# --- Health banner rollup ---
if ($overdueRedLinkCount -gt 0) {
    $healthEmoji = "🔴"
    $healthText = "$overdueRedLinkCount red link(s) at or above the ≥3-mention threshold — worth filling"
} elseif ($redLinks.Count -gt 0 -or $orphans.Count -gt 0) {
    $healthEmoji = "🟡"
    $parts = @()
    if ($redLinks.Count -gt 0) { $parts += "$($redLinks.Count) red link(s)" }
    if ($orphans.Count -gt 0) { $parts += "$($orphans.Count) orphan page(s)" }
    $healthText = ($parts -join ", ")
} else {
    $healthEmoji = "🟢"
    $healthText = "No red links or orphan pages"
}

# --- Sync status (code-sync only) ---
$syncCardHtml = ""
if ($isCodeSync) {
    $state = Get-Content $statePath -Raw | ConvertFrom-Json
    $repo = $state.project_repo
    if (-not [System.IO.Path]::IsPathRooted($repo)) { $repo = Join-Path $vault $repo }
    $branch = $state.branch
    $lastSynced = $state.last_synced_sha
    $syncRows = ""

    if (Test-Path $repo) {
        $repo = (Resolve-Path $repo).Path
        $fetchFailed = $false
        try { git -C $repo fetch origin 2>&1 | Out-Null } catch { $fetchFailed = $true }
        $fetchWarning = ""
        if ($fetchFailed) { $fetchWarning = '<div class="muted">warning: git fetch failed - using locally-cached ref</div>' }

        try {
            $head = (git -C $repo rev-parse "origin/$branch" 2>$null).Trim()
        } catch { $head = $null }

        if ($null -eq $lastSynced) {
            $syncRows = '<div class="stat-row"><span>status</span><span class="n">not bootstrapped yet</span></div>'
        } elseif ($head) {
            $shortLast = $lastSynced.Substring(0, [Math]::Min(8, $lastSynced.Length))
            $shortHead = $head.Substring(0, [Math]::Min(8, $head.Length))
            try {
                $behind = (git -C $repo rev-list --count "$lastSynced..$head" 2>$null).Trim()
            } catch { $behind = "?" }
            # wiki-state.json stores no sync-run timestamp, so show the commit date of
            # last_synced_sha instead: "the wiki covers the code as of this moment".
            $syncedUpToRow = ""
            try {
                $syncedUpTo = (git -C $repo show -s --format=%cd --date=format:'%Y-%m-%d %H:%M' $lastSynced 2>$null).Trim()
                if ($syncedUpTo) { $syncedUpToRow = "<div class=`"stat-row`"><span>synced up to</span><span class=`"n`">$syncedUpTo</span></div>" }
            } catch { }
            $headDateRow = ""
            try {
                $headDate = (git -C $repo show -s --format=%cd --date=format:'%Y-%m-%d %H:%M' $head 2>$null).Trim()
                if ($headDate) { $headDateRow = "<div class=`"stat-row`"><span>latest commit</span><span class=`"n`">$headDate</span></div>" }
            } catch { }
            $syncRows = @"
<div class="stat-row"><span>branch</span><span class="n"><code>origin/$(HtmlEscape $branch)</code></span></div>
<div class="stat-row"><span>last_synced_sha</span><span class="n"><code>$shortLast</code></span></div>
$syncedUpToRow
<div class="stat-row"><span>remote head</span><span class="n"><code>$shortHead</code></span></div>
$headDateRow
<div class="stat-row"><span>commits behind</span><span class="n">$behind</span></div>
$fetchWarning
"@
        }
    } else {
        $syncRows = '<div class="stat-row"><span class="muted">project_repo not found on disk</span></div>'
    }

    $syncCardHtml = @"
<div class="card">
  <h2>🔄 Sync status</h2>
  $syncRows
</div>
"@
}

# --- Log stats card ---
$opRows = ($opCounts.Keys | ForEach-Object { "<div class=`"stat-row`"><span>$_</span><span class=`"n`">$($opCounts[$_])</span></div>" }) -join "`n"
$logStatsCard = @"
<div class="card">
  <h2>📊 Log stats</h2>
  <div class="stat-row"><span>total entries</span><span class="n">$($entries.Count)</span></div>
  $opRows
  <div class="stat-row"><span>archived</span><span class="n">$archivedCount</span></div>
  <div class="stat-row"><span>query &rarr; answer conversion</span><span class="n">$conversionRatio</span></div>
</div>
"@

# --- Recent activity card ---
if ($recentEntries.Count -eq 0) {
    $recentItems = '<li class="empty">no log entries yet</li>'
} else {
    $recentItems = ($recentEntries | ForEach-Object {
        $tag = if ($_.Archived) { ' <span class="muted">(archived)</span>' } else { '' }
        "<li><code>[$($_.Date)] $(HtmlEscape $_.Op)</code> &mdash; $(HtmlEscape $_.Subject)$tag</li>"
    }) -join "`n"
}
$recentActivityCard = @"
<div class="card wide">
  <h2>🕒 Recent activity</h2>
  <ul class="plain">
  $recentItems
  </ul>
</div>
"@

# --- Health card ---
if ($redLinks.Count -eq 0) {
    $redLinksHtml = '<li class="empty">none</li>'
} else {
    $redLinksHtml = ($redLinks | ForEach-Object {
        if ($_.Count -ge 3) {
            "<li class=`"overdue`"><span class=`"redlink`">&#9888; [[$(HtmlEscape $_.Target)]]</span><span class=`"overdue-flag`">overdue</span><span class=`"mentions`">$($_.Count)</span></li>"
        } else {
            "<li><span class=`"redlink`">[[$(HtmlEscape $_.Target)]]</span><span class=`"mentions`">$($_.Count)</span></li>"
        }
    }) -join "`n"
}
if ($orphans.Count -eq 0) {
    $orphansHtml = '<li class="empty">none</li>'
} else {
    $orphansHtml = ($orphans | ForEach-Object { "<li>$(HtmlEscape $_)</li>" }) -join "`n"
}
$healthStateClass = ""
if ($overdueRedLinkCount -gt 0) {
    $healthStateClass = " state-danger"
} elseif ($redLinks.Count -gt 0 -or $orphans.Count -gt 0) {
    $healthStateClass = " state-warn"
}
$healthCard = @"
<div class="card wide$healthStateClass">
  <h2>🩺 Health check</h2>
  <table>
    <tr><th>Missing pages <span class="th-count">(red links &middot; $($redLinks.Count))</span></th><th>Orphan pages <span class="th-count">($($orphans.Count))</span></th></tr>
    <tr>
      <td><ul class="plain redlinks">$redLinksHtml</ul></td>
      <td><ul class="plain">$orphansHtml</ul></td>
    </tr>
  </table>
  <div class="stat-row"><span>⚠️ Superseded markers (history annotations, informational)</span><span class="n">$supersededCount</span></div>
</div>
"@

# --- Knowledge graph data + card ---
$graphEdges = @($graphEdges | Sort-Object -Property Source, Target)
$graphNodeParts = foreach ($id in $pageInfo.Keys) {
    $deg = 0
    if ($linkMentions.Contains($id)) { $deg = $linkMentions[$id] }
    "{`"id`":`"$(JsonEscape $id)`",`"label`":`"$(JsonEscape $pageInfo[$id].Label)`",`"group`":`"$(JsonEscape $pageInfo[$id].Group)`",`"degree`":$deg}"
}
$graphEdgeParts = foreach ($e in $graphEdges) {
    "{`"source`":`"$(JsonEscape $e.Source)`",`"target`":`"$(JsonEscape $e.Target)`"}"
}
$graphDataJs = "const graphData = {`"nodes`":[$($graphNodeParts -join ',')],`"edges`":[$($graphEdgeParts -join ',')]};"

$graphCard = @"
<div class="card wide graph-card">
  <h2>🕸️ Knowledge graph</h2>
  <div class="graph-controls muted">drag nodes &middot; scroll to zoom &middot; drag background to pan &middot; double-click to reset</div>
  <div id="graph-legend" class="graph-legend"></div>
  <canvas id="graph-canvas"></canvas>
</div>
"@

# --- Installed modules card ---
$modulesHtml = ($installedModules | ForEach-Object { "<li>$(HtmlEscape $_)</li>" }) -join "`n"
$modulesCard = @"
<div class="card">
  <h2>🧩 Installed modules</h2>
  <ul class="plain">$modulesHtml</ul>
</div>
"@

# --- Daily Use buttons card ---
$buttons = @(
    @{ label = "process it"; phrase = "process it" },
    @{ label = "archive this"; phrase = "archive this" },
    @{ label = "run lint"; phrase = "run lint" }
)
if ($isCodeSync) {
    $buttons += @{ label = "run sync"; phrase = "run sync" }
    $buttons += @{ label = "set commit noise"; phrase = "set commit noise" }
}
if ($isDecisions) {
    $buttons += @{ label = "record decision"; phrase = "record decision" }
}
$buttonsHtml = ($buttons | ForEach-Object {
    "<button class=`"copy-btn`" data-copy=`"$(HtmlEscape $_.phrase)`">$(HtmlEscape $_.label)</button>"
}) -join "`n"
$buttonsCard = @"
<div class="card">
  <h2>📋 Daily Use</h2>
  $buttonsHtml
  <div class="muted" style="margin-top:8px;">Click to copy a trigger phrase, then paste it into a Claude Code chat inside the vault. Query has no fixed phrase &mdash; just ask.</div>
</div>
"@

# --- Assemble ---
$html = Get-Content -Path $templatePath -Raw -Encoding UTF8
$generatedAt = Get-Date -Format "yyyy-MM-dd HH:mm"

$html = $html.Replace("%%PROJECT_NAME%%", (HtmlEscape $projectName))
$html = $html.Replace("%%GENERATED_AT%%", $generatedAt)
$html = $html.Replace("%%HEALTH_BANNER%%", "$healthEmoji $healthText")
$html = $html.Replace("%%SYNC_CARD%%", $syncCardHtml)
$html = $html.Replace("%%LOG_STATS_CARD%%", $logStatsCard)
$html = $html.Replace("%%RECENT_ACTIVITY_CARD%%", $recentActivityCard)
$html = $html.Replace("%%HEALTH_CARD%%", $healthCard)
$html = $html.Replace("%%GRAPH_CARD%%", $graphCard)
$html = $html.Replace("%%GRAPH_DATA%%", $graphDataJs)
$html = $html.Replace("%%MODULES_CARD%%", $modulesCard)
$html = $html.Replace("%%BUTTONS_CARD%%", $buttonsCard)

if (-not (Test-Path $wikiDir)) { New-Item -ItemType Directory -Path $wikiDir -Force | Out-Null }
Set-Content -Path $outPath -Value $html -Encoding UTF8

Write-Host "Dashboard written to $outPath"
Write-Host "Health: $healthEmoji $healthText"
Write-Host "Log entries: $($entries.Count) (archived: $archivedCount, query->answer: $conversionRatio)"
if ($redLinks.Count -gt 0) { Write-Host "Red links: $($redLinks.Count) (overdue: $overdueRedLinkCount)" }
if ($orphans.Count -gt 0) { Write-Host "Orphan pages: $($orphans.Count)" }
Write-Host "Knowledge graph: $($pageInfo.Count) node(s), $($graphEdges.Count) edge(s)"

try {
    Start-Process $outPath
} catch {
    Write-Host "Warning: could not open the dashboard in a browser automatically - open $outPath manually." -ForegroundColor Yellow
}

