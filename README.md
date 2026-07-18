# llm-wiki-kit

A reusable template for setting up an **LLM Wiki** — a persistent, LLM-maintained knowledge base for a project, codebase, or research topic. Background/rationale: [IDEA.md](IDEA.md). Extracted from a real, single-project instance (`examples/chain-metrics/`, project name anonymized), not designed in the abstract — see that example for what a filled-in vault actually looks like.

## Quickstart (~30 minutes)

1. Copy this `llm-wiki-kit/` folder into a new, empty directory — that directory becomes your vault.
2. Open it in Claude Code.
3. Say:

   ```text
   init vault
   ```
4. Answer the interview questions (~5, conversational, not a form). Claude assembles a single `CLAUDE.md` for your vault, **deletes the kit's own scaffolding** (`core/`, `modules/`, `examples/`, `INIT.md`, etc. — the vault is initialized in-place), and confirms it's ready.
5. Confirm the entry Claude drafts for your user-global `~/.claude/CLAUDE.md` — this is the pointer that makes sessions *in your project repo* consult the wiki instead of re-deriving answers from scratch. Without it the wiki silently goes unused.
6. Follow the handoff instructions Claude gives you (run Bootstrap if you're tracking a code repo, or ingest your first source if not).

That's it — the running vault is self-contained afterward. It never needs to reference this kit repo again; `CLAUDE.md` has everything.

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
