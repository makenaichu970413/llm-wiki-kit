# Dashboard module — implementation plan

Working plan for a second optional kit module, `modules/dashboard/`, developed on
`feature/dashboard-module` off `master`. This file is the plan, not the schema —
it gets deleted once the module is built and merged, the same way `IDEA.md` is
kit-repo-only and never ships into a vault.

## Why this exists

The human wants a "Dashboard" for a running vault: at a glance, when did it last
sync, how many log entries exist and how many are archived, what happened
recently, and what's unhealthy (stale pages, red links, contradictions) — plus
one-click access to the vault's Daily Use phrases.

## Key architecture decision

Every number the dashboard shows is mechanically derivable from files already on
disk (`log.md`, `index.md`, `wiki-state.json`, wikilink text) — none of it needs
LLM judgment. So the dashboard is **not** something Claude regenerates by hand
each time. It's a real script, `dashboard.ps1` / `dashboard.sh`, in the same
family as `sync.ps1`/`sync.sh`: no `claude -p` call, no token cost, deterministic
output, runnable standalone (double-click, cron, Task Scheduler) with no Claude
Code session open at all.

Consequence: the "buttons" on the page are **not wired to anything** — there's no
backend, no server, no execution. Clicking a button copies that Daily Use trigger
phrase to the clipboard; the human still pastes it into a Claude Code chat inside
the vault to actually run it. This was an explicit choice over a "real" one-click
backend (which would need a local server shelling out to `claude -p`, and can't
work at all for Ingest/Query since those need free-form human input) — simplicity
and zero new moving parts won over one-click convenience.

The generated `wiki/dashboard.html` is a **snapshot**, not a live view — it's only
as fresh as the last time the script ran. Freshness is handled by two triggers,
not by any file-watcher or background process (which would reintroduce a
backend, rejected for the same reason as above):

- **Manual** — human says "run dashboard" any time.
- **Automatic** — *(code-sync only)* `sync.ps1`/`sync.sh` calls `dashboard.ps1`/`.sh`
  once at the end of a successful sync, so the common case (sync, then look) never
  needs a separate manual step.

## Module scope

`modules/dashboard/`, structured like `modules/code-sync/`:

```
modules/dashboard/
├── CLAUDE.dashboard.md          # module doc: layout addendum + "run dashboard" workflow
├── scripts/
│   ├── dashboard.ps1            # Windows: compute stats, fill template, open in browser
│   └── dashboard.sh             # macOS/Linux equivalent
└── assets/
    └── dashboard.template.html  # static shell (CSS/JS inline) — scripts fill %%TOKEN%% placeholders
```

Copied into every vault that installs the module as:

```
<vault>/
├── scripts/
│   ├── dashboard.ps1
│   ├── dashboard.sh
│   └── dashboard.template.html
└── wiki/
    └── dashboard.html           # generated output, gitignored, regenerated on demand
```

Placeholder syntax in the template is `%%TOKEN%%`, deliberately different from
the kit's own `{{PLACEHOLDER}}` convention — the kit's Step 3 self-check greps
for a literal `{{` to confirm Init filled everything in, and this template's
tokens are meant to still be present after Init (they get filled by the script
at *dashboard-generation* time, not at Init time). Reusing `{{}}` would false-fail
that check.

Independent of `code-sync` — a pure-core vault can install `dashboard` alone and
gets the log/health/module-list sections; it just never shows a sync-status
section and `sync.ps1` auto-refresh doesn't apply (there's no `sync.ps1` to hook).

## `CLAUDE.dashboard.md` contents (outline)

- Frontmatter: `kit_layer: module`, `module: dashboard`, `kit_version: 0.1.0`.
- Layout addendum (above).
- **Dashboard — trigger phrase: "run dashboard"**: when the human says this,
  just run the script — don't compute any of this by hand. Report the headline
  numbers in chat too (some sessions are terminal-only, no browser handy).
  Explicitly: this is read-only, it never writes to `log.md`.
- What it shows (v1 list, below).
- Note for code-sync vaults: `sync.ps1` calls this automatically at the end of
  a successful sync — mention this once in `CLAUDE.dashboard.md` and once in
  the addendum to `CLAUDE.code-sync.md`'s Sync section (or a short cross-reference)
  so a reader of either file learns about the link.

## Dashboard content — v1

Decided in conversation, in priority order (all mechanically computed, no new
data sources beyond what's already on disk):

1. **One-line health banner** — traffic-light rollup (🟢/🟡/🔴) synthesizing the
   counts below, so the human doesn't have to read every section to know if
   anything needs attention.
2. **Sync status** *(code-sync only)* — `last_synced_sha` (short form), commits
   behind `origin/{{MAIN_BRANCH}}`.
3. **Log stats** — total entries, breakdown by op (`init`/`ingest`/`query`/
   `answer`/`lint`/`bootstrap`/`sync`/`config` as applicable), count tagged
   `⚠️ Archived`, and a **query → answer conversion ratio** (how many `query`
   entries have a matching `answer`/archive).
4. **Recent activity** — last 10 log headers, most recent first.
5. **Health check**:
   - Red links, **sorted by mention count**, flagging any at or above the
     existing Lint "≥3 mentions" threshold as "overdue" — reuses the kit's
     existing heuristic rather than inventing a new one.
   - Orphan pages (no inbound `[[link]]`, excluding `overview.md`).
   - Count of open `⚠️ Superseded` markers.
6. **Installed modules** — which modules this vault has (detected by presence
   of `wiki-state.json` etc.), since vaults built from this kit can differ.
7. **Daily Use buttons** — copy-to-clipboard only, no execution:
   - Universal: `run dashboard` (self-referential refresh reminder — useful if
     the human reopens this snapshot days later and forgets the trigger
     phrase), `process it` (Ingest a file already dropped in `raw/`),
     `archive this`, `run lint`.
   - *(code-sync only)*: `run sync`, `set commit noise`.
   - **Not** a button: Query has no fixed trigger phrase ("just ask") — the
     dashboard notes this instead of faking a button for it.

Explicitly deferred (discussed, not in v1 — revisit only if it turns out to
matter in practice):

- Diff-from-last-look (would need a small persisted state file recording the
  previous generation's numbers).
- Activity trend sparkline (log entries bucketed by week).
- Any scheduling/cron/git-hook wiring beyond the `sync.ps1` hook above.

## Kit-wide changes needed

- **`INIT.md`**
  - Step 0: becomes a 2-item checklist (`code-sync`, `dashboard`), replacing the
    current single yes/no; each is independent. Update the stale comment that
    says "if this kit ever grows a second module, this becomes a checklist."
  - Step 2: copy `scripts/dashboard.ps1`, `dashboard.sh`, `dashboard.template.html`
    into the vault; append `CLAUDE.dashboard.md` into the assembled `CLAUDE.md`;
    add a "run dashboard" bullet to the generated vault `README.md` template.
  - Step 3: dry-run check — run `dashboard.ps1`/`.sh` once, confirm
    `wiki/dashboard.html` is created without error.
  - Step 5 (Handoff): mention the dashboard in the standing notes if installed.
- **`core/.gitignore`** — add `wiki/dashboard.html` (generated artifact, safe to
  add unconditionally even for vaults without the module — the line is simply
  inert if the file never exists).
- **`modules/code-sync/scripts/sync.ps1` / `sync.sh`** — after a successful sync
  (state advanced), if `dashboard.ps1`/`.sh` exists alongside, call it. Must not
  fail the sync if the dashboard regen errors — best-effort, warn and continue.
- **Root `README.md`** — Daily Use bullet, repo layout tree, "Design principles"
  wording (currently says code-sync "is the first one" — update since it's no
  longer the only module), Prerequisites (no new prerequisite, same
  PowerShell/bash-optional note as `sync.ps1`).
- **`CHANGELOG.md`** — `[Unreleased]` entry describing the new module.
- **`examples/chain-metrics/CLAUDE.md`** — left untouched. It documents a real,
  historical vault instance that was never built with this module; retrofitting
  it would misrepresent what that vault actually ran.

## Open items / risks to watch while implementing

- PowerShell and POSIX shell will each reimplement the same wikilink-diff and
  log-parsing logic independently (same duplication `sync.ps1`/`sync.sh` already
  accept) — keep both in sync by hand, there's no shared-code mechanism here.
- `git rev-list --count` for the "commits behind" figure needs a `git fetch`
  first for accuracy; mirror `sync.ps1`'s fetch-failure fallback (warn, use the
  locally-cached ref) rather than blocking the whole dashboard on network flakiness.
- Clipboard copy from a `file://`-opened HTML page isn't guaranteed by
  `navigator.clipboard` in every browser — implement a `document.execCommand('copy')`
  fallback via a temporary textarea so the buttons work even where the async
  Clipboard API is blocked for local files.
