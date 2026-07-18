# llm-wiki-kit

A reusable template for setting up an **LLM Wiki** — a persistent, LLM-maintained knowledge base for a project, codebase, or research topic. Background/rationale: [IDEA.md](IDEA.md). Extracted from a real, single-project instance (`examples/chain-metrics/`, project name anonymized), not designed in the abstract — see that example for what a filled-in vault actually looks like.

## Quickstart (~30 minutes)

1. Copy this `llm-wiki-kit/` folder into a new, empty directory — that directory becomes your vault.
2. Open it in Claude Code.
3. Say:

   ```text
   init vault
   ```
4. Answer the interview questions (~5 — clickable option cards for the choices, plain chat for the open-ended ones like project description and repo path; falls back to fully conversational if the environment has no question tool). Claude assembles a single `CLAUDE.md` for your vault, **deletes the kit's own scaffolding** (`core/`, `modules/`, `examples/`, `INIT.md`, etc. — the vault is initialized in-place), and confirms it's ready.
5. Confirm the entry Claude drafts for your user-global `~/.claude/CLAUDE.md` — this is the pointer that makes sessions *in your project repo* consult the wiki instead of re-deriving answers from scratch. Without it the wiki silently goes unused.
6. Follow the handoff instructions Claude gives you (run Bootstrap if you're tracking a code repo, or ingest your first source if not).

That's it — the running vault is self-contained afterward. It never needs to reference this kit repo again; `CLAUDE.md` has everything.

## Day-2 usage (after Init)

The running vault's own `CLAUDE.md` defines all of this in full; Init also generates a short vault-specific `README.md` from it (this file itself doesn't survive — `INIT.md` overwrites it with one that describes the running vault instead of the kit), so a human can see what to say without opening `CLAUDE.md`. Daily operation is a handful of plain phrases said to Claude Code inside the vault:

- **`run sync`** *(code-sync)* — incremental update from new commits on the tracked branch: diff since `last_synced_sha`, skip noise commits, update only the affected pages. Also runnable headless via `scripts/sync.ps1` / `sync.sh`.
- **`set commit noise`** *(code-sync)* — tune which commits Sync skips: Claude scans your recent `git log`, shows the noise patterns it actually observed (with frequencies), you multi-select which to skip.
- **Ingest** — drop a document into `raw/` and say "process it", or just give a path in chat ("ingest D:\Downloads\note.pdf") and Claude copies it into `raw/` for you (renaming junk filenames to `<content-date>_<slug>`): summary page + updates to every affected entity page.
- **Query** — just ask; answers cite wiki pages and `file:line`. If an answer looks worth keeping, Claude proposes filing it under `wiki/answers/` — nothing gets written there without you confirming. Say **`archive this`** *(trigger phrase)* any time to file (or re-file) an answer yourself, even one Claude didn't think to offer — it also folds the finding back into the entity pages it touches, not just the answers file.
- **`run lint`** — periodic consistency check: contradictions between pages, stale claims, orphan pages, red links worth filling.

## What's in this repo

```
llm-wiki-kit/
├── CLAUDE.md            # placeholder pointing Claude at INIT.md — replaced by the assembled vault CLAUDE.md during Init
├── IDEA.md              # background/rationale — read for context, not needed at runtime
├── INIT.md              # the initialization script — what Claude follows in step 3 above
├── core/                # copied into every vault, regardless of what it tracks
│   ├── CLAUDE.core.md   # mechanism-layer schema: page format, index/log rules, Ingest/Query/Lint
│   └── wiki/            # empty index.md/log.md templates
├── modules/
│   └── code-sync/       # optional: install when the vault tracks a git repo
│       ├── CLAUDE.code-sync.md   # Bootstrap + Sync workflows
│       ├── wiki-state.json       # { project_repo, branch, last_synced_sha } template
│       └── scripts/
│           ├── sync.ps1          # Windows
│           └── sync.sh           # macOS/Linux
├── examples/
│   └── chain-metrics/CLAUDE.md   # a real, working assembled CLAUDE.md — core + code-sync filled in
└── CHANGELOG.md
```

## Design principles (see IDEA.md for the full reasoning)

- **Core is 100% standard.** Page frontmatter, `index.md`/`log.md` rules, anti-drift conventions (`⚠️ Superseded`/`⚠️ Removed`), and the Ingest/Query/Lint workflows don't change based on what the vault is about.
- **Modules are opt-in, scenario-specific.** `code-sync` is the first one — install it only if the vault tracks a git repo. A reading-notes vault or a research-topic vault stays core-only.
- **Ontology is never templated — it's proposed live.** Entity categories, page templates, language convention, and domain glossary are specific to each vault's subject matter. `INIT.md` has the LLM scan the actual source material and propose categories; the human confirms or corrects. Nothing here pre-guesses what your project's "entities" are.
- **One-way updates.** Improvements discovered in a running vault flow back into this kit manually — the kit never auto-updates a live vault's `CLAUDE.md`. Each vault's schema is its own living document.

## Status

v0.1.0 in progress — core + code-sync module built and internally consistent; the acceptance test (initializing a genuinely different kind of vault, non-code, purely from `INIT.md`) hasn't run yet. Until that passes, treat this as usable-but-unproven outside the single data-engineering instance it was extracted from.
