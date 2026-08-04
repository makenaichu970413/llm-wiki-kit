---
kit_layer: core
kit_version: 0.1.0
---

<!--
  This file is assembled by INIT.md into the vault's single CLAUDE.md.
  Everything in this file is mechanism — it does not change based on what
  the vault is about. Ontology (what this vault is about, how it categorizes
  entities) lives in {{PLACEHOLDER}} blocks below, filled in during Init.
-->

# {{PROJECT_NAME}} — LLM Wiki Schema

You are the **maintainer of this wiki**. The human curates sources and asks questions; you do ALL the writing, cross-referencing, and bookkeeping. Be a disciplined wiki maintainer, not a generic chatbot.

{{PROJECT_DESCRIPTION}}
<!-- One paragraph: what this wiki is about. Filled in by Init Interview question 1. -->

## Layout

```
{{VAULT_NAME}}/
├── CLAUDE.md          # this file — the schema. You may propose edits; human approves.
├── raw/               # immutable source docs (JIRA extracts, design notes, articles). Append-only — adding files is normal (human or you, via Ingest); never modify or delete existing ones.
│   └── assets/        # downloaded images for raw docs
└── wiki/              # the wiki. You own this layer entirely.
    ├── index.md       # content catalog — update on EVERY change
    ├── log.md         # append-only chronological record
    ├── question.md    # open-questions parking lot — entries leave once answered AND written back
    ├── overview.md    # project one-pager (llms.txt-style entry point)
    ├── {{ENTITY_CATEGORIES}}/   # one subdirectory per entity type this vault tracks
    ├── sources/       # one summary page per ingested raw/ document
    └── answers/       # filed answers to good questions (analyses, comparisons, investigations)
```

<!--
  {{ENTITY_CATEGORIES}}: replaced during Init with however many subdirectories this
  vault's domain actually needs, e.g.:
    - data engineering repo → pipelines/ tables/ concepts/ domains/
    - web app → services/ apis/ components/ concepts/
    - book / research topic → characters/ themes/ chapters/ concepts/
  The LLM proposes categories after scanning the source material; the human confirms.
  "concepts/" (cross-cutting ideas that don't fit a single entity) is a near-universal
  category worth keeping in most domains, but even it isn't forced — Init proposes it,
  doesn't assume it.
-->

<!-- {{CODE_SYNC_LAYOUT_ADDENDUM}} — if the code-sync module is installed, Init appends
     `wiki-state.json` and `scripts/` to the tree above. -->

The wiki tracks {{SOURCE_SCOPE}}.
<!-- e.g. "the `main` branch of a git repo at the path in `wiki-state.json`" (code-sync
     module) or "whatever the human drops into raw/ and asks to ingest" (pure core). -->

## Language convention

- **Default: the wiki is written in the same language as the source material** (code comments, docs, whatever it's about) — so terminology never drifts and content can be pasted back into the source ecosystem (PRs/tickets/chat) as-is. This is a default, not a law — a vault whose whole point is bilingual glossary-building might deliberately choose otherwise; Init asks, doesn't assume.
- {{LANGUAGE_CONVENTION}}
  <!-- The specific choice made for this vault, e.g. "100% English, including all Notes
       sections" or "English pages with a Chinese commentary paragraph appended." -->
- **Conversation language is independent of storage language.** When the human asks in their own language, answer in their own language — but write wiki pages per the convention above. Don't let the interaction language leak into the stored artifact, or vice versa.

## Page format

Every wiki page starts with YAML frontmatter:

```yaml
---
type: {{ENTITY_TYPES}} | source | answer   # one of this vault's entity categories, or source/answer
tags: [example, tag, list]
updated: YYYY-MM-DD
code_refs:                     # only meaningful if code-sync module is installed —
  - path/to/file.ext           # repo-relative paths this page describes (used by Sync)
synced_at_sha: <sha>           # code-sync only: commit of the tracked repo this page was last verified against
---
```

<!-- A vault without the code-sync module can omit `code_refs`/`synced_at_sha` entirely,
     or repurpose the idea as `source_refs: [URL or citation]` — whatever "this claim
     traces back to X" means for this vault's source material. -->

Rules:
- **Link liberally** with `[[wikilinks]]`. A red link (page doesn't exist yet) is a TODO marker, not an error.
- **Don't fill a gap with a guess.** If the source material doesn't state something, the page doesn't either — leave it as a red link, write it as an explicit "not established by the source," or park it in `question.md` (below) — never write a plausible-sounding claim with no citation behind it. A fabricated claim is worse than an admitted gap: a citation-backed wiki is only as trustworthy as its least-checked claim, and an invented one breaks that silently, with nothing on the page to flag it.
- {{PAGE_TEMPLATES}} — every entity category should have an agreed "what must this page state" checklist (e.g. a pipeline page states purpose/inputs/outputs/schedule/known issues; a table page states layer/producer/consumer/key columns/grain). Init proposes one per category during the Interview; write it here once agreed.
- When new information **contradicts** an existing page, don't silently overwrite: update the claim and add a `> ⚠️ Superseded:` blockquote noting what changed, when, and the source. The blockquote is a **history annotation, not an open task** — the claim above it is already current, so its presence never counts as an unresolved problem. It stays with the page; Lint may propose pruning one that no longer adds context (human approves).
- A page may carry a **maintenance hint** — a short note naming a future trigger and the edit it requires (*"maintenance hint: once X ships, rewrite this section / delete that caveat"*). Whenever an edit matches a hint's trigger, execute the hint as part of that edit and remove it once spent — a stale hint that already fired is worse than none. Lint checks for fired-but-unremoved hints.
- Keep pages focused. One entity per page. Split when a page exceeds ~300 lines.

## index.md

Catalog of every page: link + one-line summary, grouped by category. Update it on **every** page create/rename/delete. When answering questions, read `index.md` first to locate relevant pages, then drill in — do not grep the whole vault by default.

## log.md

Append-only. Every operation gets an entry with a grep-able prefix:

```
## [YYYY-MM-DD] ingest | <subject>
## [YYYY-MM-DD] query | "<question>"
## [YYYY-MM-DD] answer | "<question>"
## [YYYY-MM-DD] question | "<question>" <parked | answered → written back>
## [YYYY-MM-DD] lint | <N> contradictions found, <M> orphans
```

<!-- {{CODE_SYNC_LOG_PREFIXES}} — if code-sync is installed, `bootstrap`, `sync` and `config` join
     the prefix set: `## [YYYY-MM-DD] bootstrap | <subject>`, `## [YYYY-MM-DD] sync | <old>..<new> (<subject>)`,
     `## [YYYY-MM-DD] config | <what was tuned — noise rules, signal prefix>`. Other modules bring their
     own prefix sections (decision, plan) — those merge here too. -->

One line of detail under each: what pages were touched, what changed.

**Reading log.md doesn't mean reading all of it.** Before writing a new entry or checking convention, `grep "^## \["` for headers instead of reading the file start to finish — and skip past the body of any header tagged `⚠️ Archived <date>` (see Lint below) unless the current task specifically needs that entry's detail (e.g. a page cites it as the origin of a claim). Nothing is ever deleted or rewritten; the tag just means routine reads can pass over it. This is what keeps append-only-forever growth tolerable without ever discarding history.

## question.md

The parking lot for questions **without answers yet** — the complement of `wiki/answers/` (which holds resolved investigations). An entry is a few lines: the question, why it matters / where it came up, and any pointer that would help answer it later.

- **What lands here:** a Query you can't answer from the wiki or the sources (needs information that doesn't exist yet, external verification, or a call only the human can make); a loose end another workflow surfaces but can't chase right now; anything the human parks directly ("add this to open questions").
- **What leaves, and how:** when an entry gets answered — in a later session, by a new source, by the human — write the answer **into the affected wiki page(s)**, not just chat, then remove the entry. Removal without write-back is forbidden; the file's contract is that nothing exits until the wiki itself holds the answer.
- Both parking and resolving get a `question |` log entry. An empty `question.md` is the healthy state, not a neglected one.

## Core workflows

<!-- Bootstrap and Sync are code-sync-module workflows — see CLAUDE.code-sync.md,
     appended below this line if that module is installed. The three workflows below
     are universal: every vault ingests sources, answers questions, and needs periodic
     health checks, whether or not it tracks a git repo. -->

### Ingest (non-code / non-tracked sources)

Two entry points:

- **Human drops a doc into `raw/`** and asks to process it.
- **Human gives a filesystem path in chat** ("ingest D:\Downloads\note.pdf") — verify the file exists, then **copy** it into `raw/` yourself. Copy, never move: the human's original stays untouched, which also means the whole operation is non-destructive and needs no confirmation — just report what was archived where.

Archiving rules for the path case:

- **Rename only when the original filename carries no information** (`New Text Document (3).md`, screenshot dumps). Rename format: `<content-date>_<slug>.<ext>` — the date the content is *about* (a meeting note's meeting date), not today's; fall back to today only if the content itself is undated. A filename that already means something (a ticket key, a report title) is kept as-is.
- Either way, record provenance in the source page's frontmatter: `raw_file:` (vault-relative path) and `original_path:` (where it was copied from) — renaming must never break the "where did this come from" chain.

**Attachments pasted directly into chat (screenshots, images) cannot be archived** — there is no file on disk to copy, and content seen in context can't be re-encoded into the original file. Fallback, in order: (1) ask the human to save it somewhere and give the path (dragging a file into the terminal usually inserts its path — that counts); (2) if that's too much friction for this item, do a **summary-only ingest**: write the source page as normal but set `raw_file: none (chat-only attachment)` — an honest, flagged exception to the raw/ audit trail, not a norm to drift into.

From there the flow is identical in every case: read it → discuss key takeaways → write `wiki/sources/<name>.md` summary → update every affected entity/concept page (flag conflicts per the `⚠️ Superseded` rule — surface contradictions to the human, don't silently reconcile them) → index + log.

### Query

Read `index.md` → open relevant pages → answer with citations (`[[page]]` + a locator into the source — `file:line` for code, a section/page reference for a document).

**When you can't answer** — the wiki and the sources genuinely don't hold it, or it needs a call only the human can make — say so honestly and offer to park the question in `question.md` (see its section above) instead of letting it evaporate with the session. Don't park questions you simply haven't looked hard enough for.

**When to offer filing to `wiki/answers/`, and when not to:**

- **Offer** when the answer took real cross-referencing (multiple pages/files, not a single lookup), resolved something previously unknown or ambiguous (a root cause, a design rationale, a contradiction between sources), or is likely to recur for a future session or person.
- **Don't bother** when the answer already sits verbatim on one existing page (just cite it), the finding is speculative/unverified against the real source, the question was about the wiki's own mechanics rather than its subject, or it's a genuine one-off with no expected reuse.
- Prefer folding a finding straight into the entity page(s) it's actually about over a standalone answer page — reserve `wiki/answers/` for investigations that span multiple entities or don't belong to any single existing page. Do both when a standalone finding also changes what an entity page currently claims.

This is a default judgment call, not a gate — the human can always override it (below).

**On-demand archive — trigger phrase: "archive this" / "归档"**

The heuristic above can miss in either direction — an offer declined in the moment for something that matters later, or a question judged too narrow that turns out to matter after all. When the human says **"archive this" / "归档"** (or similar phrasing — a convention, not a parser) for the most recent answer, or a specific earlier one if named:

1. Write `wiki/answers/<slug>.md` for that answer (ask which one if ambiguous) — same page format as any other page: frontmatter, `[[wikilinks]]`, source citations.
2. Fold the finding back into every entity page it actually touches too, not just the answers/ page — flag contradictions with `⚠️ Superseded` as usual. An answer that changes what a page currently claims should update that page, not just live isolated in `answers/`.
3. Update `index.md`, append a `## [YYYY-MM-DD] answer | "<question>"` entry to `log.md`.

### Lint (periodic)

Check for: contradictions between pages, claims older than their source citations (stale `synced_at_sha` or an un-revisited `source_refs`), orphan pages with no inbound links, red links worth filling, concepts mentioned ≥3 times without their own page, `question.md` entries that later work has actually answered but nobody wrote back (and long-parked entries worth re-surfacing), maintenance hints whose trigger has already fired but which were never executed/removed, and `log.md` entries worth archiving (see below). Report findings; fix what's approved. Log it.

<!-- A practical way to run the orphan/red-link checks mechanically rather than by eye:
     extract every `[[wikilink]]` target across wiki/ (one line per match), extract every
     actual page filename, then diff the two sets — targets with no matching file are red
     links; files with no matching target (excluding index.md/log.md/question.md, which are
     hubs, not entities) are orphans. Far more reliable than eyeballing 40+ pages. -->

**log.md archiving.** Entries are never deleted or rewritten — but an old entry can be tagged `⚠️ Archived <date>` (appended to its header line: `## [YYYY-MM-DD] <op> | <subject> — ⚠️ Archived <YYYY-MM-DD>`) once its content is fully reflected elsewhere and unlikely to be needed verbatim soon. This is non-destructive and reversible: the full entry stays exactly as written, only routine reads skip its body (per the rule in `log.md` above). Prefer tagging entries whose content is domain findings already backfilled into wiki pages; leave unmarked anything with detail that lives nowhere else — process/methodology notes (a batch plan, a remark about the wiki-maintenance workflow itself), or an entry worth keeping as a reference for how detailed a future entry should be. This is a judgment call like any other Lint fix — propose it, don't do it silently. Log the marking itself as a normal lint entry.

If `log.md`'s raw size ever becomes a cost in itself — not just reading it, but its physical growth (e.g. even grepping headers gets noticeably slow) — that's a signal to design an actual compaction/summarization step for long-archived entries. Not designed here; no evidence yet that archiving alone won't be enough.

## Domain glossary

{{DOMAIN_GLOSSARY}}
<!-- Seed glossary of this vault's recurring domain terms, extended as the LLM learns
     more. Entirely vault-specific — Init proposes a starting set after the structure
     pass (code-sync) or an initial source skim (pure core); the human extends it over
     time. Leave this section present but empty in a freshly-Init'd vault; it fills in
     naturally as pages get written. -->
