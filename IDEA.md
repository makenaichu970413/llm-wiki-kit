# IDEA — background, not operating instructions

This kit implements a pattern popularly associated with Andrej Karpathy: an LLM maintains a persistent, structured knowledge base about a project over time, rather than re-deriving context from scratch in every session. The human's role shifts from "explain the codebase again" to "curate sources and ask questions" — the LLM does the reading, writing, and cross-referencing; the wiki accumulates.

This file exists for background only — nothing in it is executed at runtime. If you're setting up a new vault, go to `INIT.md`. If you're maintaining an existing vault, its own `CLAUDE.md` is authoritative. This file is not a verbatim transcript of anyone's writing — it's this kit's own restatement of the idea, kept here so a reader understands *why* the kit is shaped the way it is before they start customizing it.

## Why this shape, specifically

- **A wiki, not a chat log.** Chat history is chronological and lossy — the tenth conversation about the same subsystem re-explains what the first one already covered. A wiki is organized by *subject*, so new information updates an existing page instead of piling up as another transcript.
- **The LLM owns the writing.** The human doesn't maintain the wiki by hand — that defeats the point. The human's job is judgment (what's worth ingesting, which answers are worth filing, approving proposed structure); the LLM's job is everything mechanical (reading, cross-referencing, keeping `index.md`/`log.md` current, catching contradictions).
- **Verify before writing, always.** A wiki is only valuable if it's *more* trustworthy than asking the LLM cold — which means every claim should trace back to something checked, not something remembered. This is why every page carries a source citation, why Sync re-derives from a diff instead of trusting stale notes, and why Lint explicitly checks for claims that have gone stale.
- **Bootstrap is a front-loaded cost, not a free lookup.** A first full pass over a codebase (or reading corpus) is the most expensive thing this kit does — real token spend to distill file-level detail down into page-level, cited claims. That cost only pays for itself if the wiki then gets queried repeatedly; a vault built once and never asked again is a net loss. The payoff compounds two ways: routine queries afterward skip re-reading what's already been distilled, and a full structural pass tends to surface things a single narrowly-scoped question never would have gone looking for.
- **Structure precedes content, deliberately.** Bootstrap's structure pass (a directory-tree scan with no file contents) happens before any page gets real content — it's cheap, and it often surfaces real insight on its own (a mismatch between where something *lives* and what it's actually *for* is a common, useful early finding).
- **Extraction from one real instance, not upfront design.** This kit itself follows the pattern it describes: it was pulled out of a working single-project vault (`examples/chain-metrics/`, project name anonymized) after that vault had gone through a full real-usage cycle, not designed in the abstract first. See this repo's own `PLAN.md` (kept private to the extraction process, not part of the kit's runtime surface) if you want the full reasoning trail.

## What this kit is not

- Not a framework. No installer, no config system, no dependencies beyond `git` and the `claude` CLI. Copy the files, run Init, done.
- Not a replacement for judgment. The LLM proposes; the human still approves structural decisions (entity categories, page templates, language convention) during Init, and approves Lint fixes before they land.
- Not finished after v0.1.0. A kit extracted from a single project (`chain-metrics`, a data-engineering repo) necessarily carries that project's biases. It needs a second, differently-shaped vault to prove the abstraction holds — see `PLAN.md` §6 in the source project if that acceptance test hasn't run yet.
