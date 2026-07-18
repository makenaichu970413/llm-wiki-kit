---
kit_layer: module
module: code-sync
kit_version: 0.1.0
---

<!--
  Appended to core/CLAUDE.core.md by INIT.md when the vault tracks a git repo.
  Adds: wiki-state.json state file, Bootstrap workflow, Sync workflow, and the
  bootstrap/sync log-prefixes. Ships with scripts/sync.ps1 + scripts/sync.sh.
-->

## Code-sync layout addendum

```
{{VAULT_NAME}}/
├── wiki-state.json    # sync state: { project_repo, branch, last_synced_sha }
└── scripts/
    ├── sync.ps1       # diff-driven incremental sync (Windows)
    └── sync.sh        # same, macOS/Linux
```

The project code lives at the path in `wiki-state.json → project_repo`. Code is a **source**, read-only from the wiki's perspective. The wiki tracks **`{{MAIN_BRANCH}}` only** — feature branches don't exist here until merged.

## Bootstrap (one-time)

1. **Structure pass:** scan the project repo's directory tree only (no file contents). Create `overview.md`, top-level entity-category pages, and a skeleton `index.md` with red links for every page that should eventually exist. This pass alone often produces real insight — explicitly note any place the directory structure doesn't match the logical structure (e.g. "these notebooks live under `X/` but actually serve domain `Y`"), don't treat it as pure scaffolding.
2. **Module passes:** ingest one batch of related files at a time (propose batch boundaries after the structure pass — group by subsystem/domain, not by file count). For each batch: read the code, write/fill the pages, update index + log, commit — each batch boundary is a clean resume point if the session dies mid-Bootstrap.
   - **Pacing — the human is needed at exactly two points, not between every batch:** (1) **the batch plan**, right after the structure pass — show the proposed batches and get confirmation; this is a real decision (a too-heavy batch gets split here). (2) **after batch 1** — stop and have the human spot-check the output (page depth, Notes quality, granularity); a style mistake caught here costs one batch of rework, caught at the end it costs all of them. Once batch 1 passes, run the remaining batches straight through with a one-line progress note per batch — do **not** ask for confirmation between them. Stop mid-run only on genuine anomalies: a contradiction with an already-written page, an unplanned oversized area, or context pressure that warrants a fresh session. The human can override either way at any batch boundary ("confirm every batch" / "switch back to auto") — offer both, don't lock in. Use the interactive question tool for these confirmations when the environment has one — clickable options beat typed replies.
   - **Verify inherited "known issues" against current code, don't just transcribe them.** If prior working notes/memory claim a bug is still live, check with `git log --follow -p` (or equivalent) before writing it into the wiki as current fact — a fix landed after the note was written is a common way stale claims propagate. When a claim turns out stale, correct it with the `⚠️ Superseded` pattern (see core's page-format rules) rather than silently updating it — and when a claim turns out to be accurate, say so explicitly too, not just when correcting something.
   - **Oversized source files** (a single file too large for one Read call): extract just the meaningful content into a flat text dump first (for code notebooks: one file's worth of cell source, `===== CELL N =====`-delimited), then grep/read that in sections — much faster than repeated truncated reads of the raw format.
3. Finish by setting `wiki-state.json → last_synced_sha` to the repo's current `origin/{{MAIN_BRANCH}}` SHA.

## Sync (incremental — triggered by `scripts/sync.ps1`/`sync.sh` or manually)

1. Read `wiki-state.json`. Diff the project repo: `git diff --name-status <last_synced_sha>..origin/{{MAIN_BRANCH}}` (plus `git log --oneline` for context). If `last_synced_sha` is `null` but Bootstrap has already run, treat the SHA Bootstrap finished at as the effective baseline rather than blocking — Sync and Bootstrap share one timeline.
2. **Triage:** ignore noise ({{SYNC_TRIAGE_RULES}}) unless it reveals a data/behavior issue worth recording. Decide which changes carry knowledge.
3. Map changed files → affected pages via `code_refs` frontmatter and `index.md`. Read only the changed files (and diffs), update the affected pages, flag contradictions per the `⚠️ Superseded` rule.
4. If a change introduces a new entity worth its own page, create it. If something was deleted, mark the page `> ⚠️ Removed in <sha>` — don't delete pages, history has value.
5. **Cross-check working memory while you're in there, not just the diff.** A commit range is also a good moment to notice a memory note that's gone stale even though it wasn't touched by this specific diff — Sync's "verify before writing" discipline generalizes past just the files that changed.
6. Update `index.md`, append to `log.md` (`sync | <old>..<new>`), advance `last_synced_sha`.

<!--
  {{SYNC_TRIAGE_RULES}}: repo-specific noise patterns to skip by default, e.g.
  "[CHECK]-prefixed commits (data validation runs, not code changes)", "chore:/version-bump
  commits", "formatting-only diffs". Filled in during Init Interview, refined as real
  Syncs reveal patterns that weren't anticipated.
-->

## `scripts/sync.ps1` / `sync.sh`

Both scripts: read `wiki-state.json`, fetch the tracked repo, diff `last_synced_sha..origin/{{MAIN_BRANCH}}`, and hand the range + changed-file list to a headless `claude -p` run instructed to execute the Sync workflow above, then verify `last_synced_sha` actually advanced.

**`git fetch` can time out or hang** (credential prompt, network issue) — don't let that abort the whole run. If fetch fails, fall back to whatever `origin/{{MAIN_BRANCH}}` already resolves to locally and print a visible warning that the diff may be stale, rather than crashing.
