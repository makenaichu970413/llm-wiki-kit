# Changelog

Versioning: MAJOR = architecture change (directory/state-file mechanism) · MINOR = workflow improvement · PATCH = wording/documentation fix.

## [Unreleased]

### Changed

- Quickstart trigger phrase shortened to a copyable `init vault` block; added a root-level placeholder `CLAUDE.md` that points fresh sessions at `INIT.md` (auto-loaded by Claude Code, so the short phrase resolves deterministically). It's overwritten by the assembled vault `CLAUDE.md` during Init Step 2.

- `INIT.md` Step 2 now deletes the kit's own scaffolding (`core/`, `modules/`, `examples/`, `INIT.md`, `IDEA.md`, `README.md`, `CHANGELOG.md`, and a cloned kit's `.git/`) before the vault's initial commit — previously this was left for the human to clean up manually, and the "self-contained vault" promise depended on them remembering to.
- `INIT.md` interview now runs in **mixed mode**: closed-choice questions (module selection, entity categories, language convention, sync-noise rules, tracked branch) go through the environment's interactive question tool (option cards — `AskUserQuestion` in Claude Code) when one is available; open-ended answers (project description, repo path — asked with an OS-appropriate example path) stay in chat; and the tracked branch is picked from a real `git branch` listing instead of typed by hand. Falls back to fully conversational when no question tool exists, so the interview still works outside Claude Code.
- Bootstrap pacing reworked (`modules/code-sync/CLAUDE.code-sync.md`): instead of confirming with the human between every batch (a rubber-stamp in practice — humans type "continue" without reviewing), the human is needed at exactly two points — the batch plan, and a batch-1 style spot-check — after which the remaining batches run straight through with one-line progress notes, stopping only on genuine anomalies (contradictions with existing pages, unplanned oversized areas, context pressure). Each batch still commits, so batch boundaries stay clean resume points; either mode can be switched at any boundary.
- `INIT.md` gained a Step 4 — **Register the vault in the user-global `~/.claude/CLAUDE.md`** (with human confirmation, since it edits a file outside the vault). Without this pointer, sessions working in the project repo never think to consult the wiki, and it silently goes unused. Old Step 4 (Handoff) is now Step 5; the self-check gained a matching "no kit files remain, no kit git history" check.

Extracted from a private single-project vault (a data-engineering wiki; anonymized here as `chain-metrics`) after it completed one full real-usage cycle (5 real Queries, 5 real Ingests, 1 Sync, 1 Lint — see that project's `PLAN.md` §2/§9 for the extraction evidence trail). Extraction was started deliberately before the originally-planned gate (≥5 Sync runs, 2-week `CLAUDE.md` stability window) finished, by explicit decision of the vault's maintainer — noted here rather than glossed over, since it means this kit's `code-sync` module has only been battle-tested against one real Sync so far, not the five originally intended.

Not yet released as `v0.1.0` — that tag is reserved for after the acceptance test (§6 in the source project's `PLAN.md`: initializing a genuinely different kind of vault — non-code, e.g. a book or a research topic — purely from `INIT.md`, with no prior context) passes. Until then, treat every file here as usable-but-unproven outside the single data-engineering instance (`examples/chain-metrics/`) it came from.

### Added

- `core/CLAUDE.core.md` — mechanism-layer schema: role framing, layout skeleton, language-convention default, page-frontmatter format, `index.md`/`log.md` rules, anti-drift conventions, Ingest/Query/Lint workflow definitions, domain-glossary placeholder.
- `modules/code-sync/` — Bootstrap (two-pass) + Sync (diff-driven + triage) workflows, `wiki-state.json` template, `scripts/sync.ps1` + `scripts/sync.sh` (functionally equivalent, both with a `git fetch` failure fallback that the source project's own experience log flagged as missing but never implemented until now).
- `INIT.md` — module-selection question, ~5-question interview, assembly/instantiation steps, self-check, handoff script.
- `IDEA.md` — background/rationale, written fresh for this kit (not a verbatim transcript of any external source).
- `examples/chain-metrics/CLAUDE.md` — the real, working assembled schema from the source vault (project name anonymized), included as a concrete "filled in like this" reference alongside the templated `core`/`modules` files.
