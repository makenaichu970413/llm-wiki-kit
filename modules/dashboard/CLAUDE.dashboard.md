---
kit_layer: module
module: dashboard
kit_version: 0.1.0
---

<!--
  Appended to core/CLAUDE.core.md by INIT.md when the human opts into the
  dashboard module (independent of code-sync — see Step 0). Adds: the
  dashboard.ps1/.sh scripts, dashboard.template.html shell, and the
  "run dashboard" trigger phrase. Ships with scripts/dashboard.ps1 +
  scripts/dashboard.sh + scripts/dashboard.template.html.
-->

## Dashboard layout addendum

```
{{VAULT_NAME}}/
├── scripts/
│   ├── dashboard.ps1            # compute stats, fill template, open in browser (Windows)
│   ├── dashboard.sh             # same, macOS/Linux
│   └── dashboard.template.html  # static shell the scripts fill in — not hand-edited per run
└── wiki/
    └── dashboard.html           # generated snapshot — gitignored, regenerated on demand
```

Everything the dashboard shows is mechanically derived from files already on disk (`log.md`, `index.md`, `wiki-state.json` if present, wikilink text) — no LLM judgment is involved in computing it. That's why it's a real script, not something you recompute by hand each time.

## Dashboard — trigger phrase: "run dashboard"

When the human says this, **run the script** — don't compute any of the numbers below by hand:

- Windows: `scripts\dashboard.ps1`
- macOS/Linux: `scripts/dashboard.sh`

The script writes `wiki/dashboard.html` and opens it in the default browser. After it runs, **report the headline numbers in chat too** — some sessions are terminal-only with no browser handy, so the chat report is not optional. This is read-only: it never writes to `log.md`, `index.md`, or any wiki page.

*(code-sync vaults only)* `scripts/sync.ps1` / `sync.sh` already calls the dashboard script automatically at the end of a successful sync (see the Sync section) — so after "run sync" the human will usually see a browser tab open on its own, without a separate "run dashboard" ask. See `CLAUDE.code-sync.md`'s Sync section for that link.

## What it shows (v1)

All of it computed from files on disk, no free-form reading required:

1. **One-line health banner** — a traffic-light rollup (🟢/🟡/🔴) synthesizing the counts below, so the human doesn't have to read every section to know if anything needs attention.
2. **Sync status** *(code-sync only)* — `last_synced_sha` (short form) from `wiki-state.json`, and commits behind `origin/{{MAIN_BRANCH}}`.
3. **Log stats** — total `log.md` entries, breakdown by op (`init`/`ingest`/`query`/`answer`/`question`/`lint`/`bootstrap`/`sync`/`config`/`decision`/`plan` as applicable to this vault — the scripts count whatever ops actually appear, no fixed list), count tagged `⚠️ Archived`, and a **query → answer conversion ratio** (how many `query` entries have a matching `answer`/archive entry for the same question).
4. **Recent activity** — the last 10 `log.md` headers, most recent first.
5. **Health check**:
   - Red links (wikilink targets with no matching page file), **sorted by mention count**, flagging any at or above the Lint "≥3 mentions" threshold as "overdue" — reuses the kit's existing heuristic rather than inventing a new one.
   - Orphan pages (no inbound `[[link]]`, excluding `overview.md`, `index.md`, `log.md`, `question.md` — hub files, not entities).
   - Count of `⚠️ Superseded` markers across wiki pages — **informational only** (per the core page-format rule they're history annotations, not open issues), so this count never degrades the health banner.
6. **Knowledge graph** — an Obsidian-style force-directed graph of every wiki page (node) and the `[[wikilinks]]` between them that resolve to a real page (edge; red links aren't drawn as edges — they already show up in the Health check above). Nodes are colored by their top-level `wiki/` subfolder and sized by inbound-link count (degree); drag a node, drag the background to pan, scroll to zoom, double-click to reset. The layout itself (node positions) is a live client-side physics simulation, not something the script computes — the script only computes the node/edge *data* (ids, labels, groups, degrees), deterministically, the same as every other card.
7. **Installed modules** — which optional modules this vault has installed (detected by marker files: `wiki-state.json` for code-sync, `wiki/decisions/` for decisions, `wiki/plan.md` for roadmap, `wiki/tickets/` for tickets, `wiki/flows/` for flows), since vaults built from this kit can differ.
8. **Daily Use buttons** — copy-to-clipboard only, nothing executes from the page itself:
   - Universal: `process it`, `archive this`, `run lint`.
   - *(code-sync only)*: `run sync`, `set commit noise` (also sets the signal-prefix override).
   - *(decisions only)*: `record decision`.
   - *(tickets only)*: `create ticket`.
   - *(flows only)*: `flow it`.
   - Query has no fixed trigger phrase ("just ask") — the dashboard notes this instead of faking a button for it.

The generated page is a **snapshot**, not a live view — only as fresh as the last time the script ran. Re-run it any time with "run dashboard", or rely on the automatic post-sync refresh in code-sync vaults.
