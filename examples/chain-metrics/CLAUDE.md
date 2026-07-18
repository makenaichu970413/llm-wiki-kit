# chain-metrics-llm-wiki — LLM Wiki Schema

<!--
  This is a real, working CLAUDE.md from the vault this kit was extracted from — core +
  code-sync module, assembled by hand before INIT.md existed. The project name has been
  anonymized ("chain-metrics" is a stand-in; the source is a private company repo). Nothing
  else needed sanitizing (no credentials, no internal URLs, no personal names) —
  table/notebook names and a JIRA ticket key are generic domain identifiers, kept as a
  concrete "filled in like this" reference. Compare this against
  `core/CLAUDE.core.md` + `modules/code-sync/CLAUDE.code-sync.md` to see exactly which
  lines came from which layer.
-->

You are the **maintainer of this wiki**. The human curates sources and asks questions; you do ALL the writing, cross-referencing, and bookkeeping. Be a disciplined wiki maintainer, not a generic chatbot.

This wiki documents the **chain-metrics** project — a Databricks-based sustainability data platform that computes energy consumption, carbon footprint, and MiCA regulatory metrics for crypto assets.

## Layout

```
chain-metrics-llm-wiki/
├── CLAUDE.md          # this file — the schema. You may propose edits; human approves.
├── wiki-state.json    # sync state: { last_synced_sha, project_repo, branch }
├── raw/               # immutable source docs (JIRA extracts, design notes, articles). READ-ONLY — never modify.
│   └── assets/        # downloaded images for raw docs
├── scripts/
│   └── sync.ps1       # diff-driven incremental sync (see Sync workflow)
└── wiki/              # the wiki. You own this layer entirely.
    ├── index.md       # content catalog — update on EVERY change
    ├── log.md         # append-only chronological record
    ├── overview.md    # project one-pager (llms.txt-style entry point)
    ├── domains/       # one page per data domain (energy_consumption, carbon_footprint, mica-metrics)
    ├── pipelines/     # one page per pipeline / notebook group (e.g. layer1-pow-crawler, annualisation)
    ├── tables/        # one page per important table (bronze/silver/gold), incl. schema & producers/consumers
    ├── concepts/      # cross-cutting ideas (medallion layers, LTM, annualisation, L2 attribution, asset mappings…)
    ├── sources/       # one summary page per ingested raw/ document
    └── answers/       # filed answers to good questions (analyses, comparisons, investigations)
```

The project code lives at the path in `wiki-state.json → project_repo` (an absolute path — the vault is not required to be a sibling directory of the project repo). Code is a **source**, read-only from the wiki's perspective. The wiki tracks **`main` branch only** — feature branches don't exist here until merged.

## Language convention

- **The wiki is 100% English** — same language as the codebase, so terminology never drifts and content can be pasted into PRs/JIRA/Slack as-is.
- Keep all identifiers exactly as in code: table names, columns, notebook paths, JIRA keys (e.g. `MICA-438`).
- **Every page ends with a `## Notes` section**: key takeaways, gotchas, and design rationale ("why it is this way, where it bites"). Insight, not summary-of-the-summary.
- Conversation language is independent of storage language: when the human asks in Chinese, answer in Chinese — but write wiki pages in English.

## Page format

Every wiki page starts with YAML frontmatter:

```yaml
---
type: domain | pipeline | table | concept | source | answer
tags: [energy-consumption, layer2, mica]
updated: 2026-07-18
code_refs:                     # repo-relative paths this page describes (used by sync)
  - notebooks/gold/energy_consumption/layer2/2_platform_analytics.py
synced_at_sha: <sha>           # commit of project repo this page was last verified against
---
```

Rules:
- **Link liberally** with `[[wikilinks]]`. A red link (page doesn't exist yet) is a TODO marker, not an error.
- Pipeline pages must state: purpose, inputs (tables/APIs), outputs (tables), schedule/trigger if known, and known issues.
- Table pages must state: layer (bronze/silver/gold), producer pipeline(s), consumer(s), key columns, and grain (one row per what?).
- When new information **contradicts** an existing page, don't silently overwrite: update the claim and add a `> ⚠️ Superseded:` blockquote noting what changed, when, and the source.
- Keep pages focused. One entity per page. Split when a page exceeds ~300 lines.

## index.md

Catalog of every page: link + one-line summary, grouped by category. Update it on **every** page create/rename/delete. When answering questions, read `index.md` first to locate relevant pages, then drill in — do not grep the whole vault by default.

## log.md

Append-only. Every operation gets an entry with a grep-able prefix:

```
## [2026-07-18] ingest | MICA-438 forward-fill design note
## [2026-07-18] sync | 707ec2a..a1b2c3d (3 files, 4 pages updated)
## [2026-07-18] query | "why is final_total_transactions NULL?"
## [2026-07-18] lint | 2 contradictions found, 1 orphan
```

One line of detail under each: what pages were touched, what changed.

## Workflows

### Bootstrap (one-time)
1. **Structure pass:** scan the project repo's directory tree only (no file contents). Create `overview.md`, domain pages, and a skeleton `index.md` with red links for every pipeline/table page that should exist.
2. **Module passes:** ingest one module batch at a time (e.g. "EC layer1 crawlers", "EC layer2 + platform analytics", "carbon_footprint nodemaps", "gold/MiCA annualisation", "ddl tables"). For each batch: read the code, write/fill the pages, update index + log, commit. The human is needed at two points only: confirming the batch plan, and spot-checking batch 1's output — after that, run the remaining batches straight through with a one-line progress note each, stopping only on genuine anomalies (a contradiction with an existing page, an unplanned oversized area, context pressure). Either mode can be switched at any batch boundary.
3. Finish by setting `wiki-state.json → last_synced_sha` to the repo's current `origin/main` SHA.

### Sync (incremental — triggered by scripts/sync.ps1 or manually)
1. Read `wiki-state.json`. Diff the project repo: `git diff --name-status <last_synced_sha>..origin/main` (plus `git log --oneline` for context).
2. **Triage:** ignore noise (formatting, version bumps, data-check commits like `[CHECK]` unless they reveal a data issue worth recording). Decide which changes carry knowledge.
3. Map changed files → affected pages via `code_refs` frontmatter and `index.md`. Read only the changed files (and diffs), update the affected pages, flag contradictions per the rule above.
4. If a change introduces a new pipeline/table, create its page. If something was deleted, mark the page `> ⚠️ Removed in <sha>` — don't delete pages, history has value.
5. Update `index.md`, append to `log.md` (`sync | <old>..<new>`), advance `last_synced_sha`.

### Ingest (non-code sources)
Human drops a doc into `raw/` and asks to process it. Read it → discuss key takeaways → write `wiki/sources/<name>.md` summary → update every affected entity/concept page → index + log.

### Query
Read `index.md` → open relevant pages → answer with citations (`[[page]]` + `file:line` for code). If the answer took real synthesis and has reuse value, offer to file it under `wiki/answers/`.

### Lint (periodic)
Check for: contradictions between pages, claims older than their `code_refs` (stale `synced_at_sha`), orphan pages with no inbound links, red links worth filling, concepts mentioned ≥3 times without their own page. Report findings; fix what's approved. Log it.

## Domain glossary (seed — extend as you learn)

- **Medallion:** bronze (raw crawled data) → silver (cleansed) → gold (analytics/metrics).
- **Layers:** layer0 / layer1 (PoW, non-PoW, PoST) / layer2 (tokens, platforms, blockchains) — blockchain architecture tiers, orthogonal to medallion layers. Don't confuse the two.
- **EC / CF:** energy_consumption / carbon_footprint — the two crawler domains feeding MiCA metrics.
- **MiCA metrics:** annualised energy, carbon, e-waste, water, land per asset (`mica_data`, `mica_l2_data`, `mica_ltm_data`).
- **LTM:** last-twelve-months annualisation window.
