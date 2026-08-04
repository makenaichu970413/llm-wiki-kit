---
kit_layer: module
module: decisions
kit_version: 0.1.0
---

<!--
  Appended to core/CLAUDE.core.md by INIT.md when the human opts into the
  decisions module (independent of every other module — see Step 0). Adds:
  the wiki/decisions/ directory, the ADR page format and lifecycle rules,
  the "record decision" trigger phrase, the decision log-prefix, and Lint
  checks for ADR consistency. Ships no scripts — this module is pure schema.
-->

## Decisions layout addendum

```
{{VAULT_NAME}}/
└── wiki/
    └── decisions/     # Architecture Decision Records — why things are the way they are
```

Decisions record **why** — the pages elsewhere in the wiki describe what is; a decision page preserves what else was considered, why the winner won, and what the choice costs. One decision per file, named `NNNN-short-slug.md` (`0001-postgres-over-sqlite.md`), numbered in creation order starting at `0001`. Numbers are never reused, even if a decision is later superseded.

**Decisions are the human's, not yours.** You draft, propose, and keep the records consistent — but a decision only becomes `accepted` when the human says so. Never promote a status or file a new ADR silently.

## Decision page format

Frontmatter adds a `status` field to the core page format (`type: decision`):

```yaml
---
type: decision
status: proposed | accepted | superseded
decided: YYYY-MM-DD        # date the human accepted it — absent while proposed
tags: [...]
updated: YYYY-MM-DD
---
```

Body skeleton — every decision page states:

- **Status** — one line mirroring the frontmatter (`accepted (YYYY-MM-DD)`; if superseded: `superseded by [[NNNN-successor]]`). Frontmatter, this line, and the `index.md` entry must always agree — Lint checks this.
- **Context** — what problem forced a choice.
- **Options considered** — including the rejected ones and why they lost. Rejected options are the most valuable part of the page: they stop the same debate from being re-run from scratch a year later.
- **Decision** — what was chosen, in one or two sentences.
- **Consequences** — what this makes hard to reverse, what follow-up it obligates.
- Links to the entity pages the decision affects.

## Decision lifecycle

- `proposed` — drafted, awaiting the human's call. A vault can hold proposed ADRs indefinitely, but Lint surfaces ones that have sat unresolved (see below).
- `accepted` — the human confirmed it; record `decided:`.
- `superseded` — the decision was overturned. **Never delete or rewrite the file**: set its status to `superseded`, add the pointer to its successor, and open a **new** ADR (next number) explaining what changed and why. Decision history is the whole point of this directory.
- **Two levels of "superseded" — keep them straight.** The core `> ⚠️ Superseded:` blockquote revises a *single claim inside any page*; ADR `status: superseded` overturns a *whole decision file*. When an ADR is overturned, the entity pages that relied on it get statement-level `⚠️ Superseded` blockquotes citing the successor ADR — the two mechanisms work together, one per level.
- **Retroactive ADRs are legitimate.** A decision made long before this vault existed (visible in the source material, or explained by the human) can be filed as `accepted` with `decided:` set to the historical date if known — a backfilled why is worth as much as a fresh one. Flag it as retroactive in Context. Like any other ADR, it is shown to the human and filed only on their confirmation — the historical date backfills `decided:`, not the approval step.

## Recording decisions — trigger phrase: "record decision"

Two entry points, mirroring how answers get filed:

- **The human says "record decision"** (or any similar phrasing — a convention, not a parser) after a choice crystallizes in conversation: draft the ADR from the discussion (Context, the options actually weighed, the pick, the costs), show it, and file it with the status the human names — straight to `accepted` if they've already decided, `proposed` if it still needs sign-off from someone else.
- **You offer.** When work in any other workflow surfaces a genuine fork that got picked — an Ingest document that explains why an approach was taken, a Query that reconstructs a rationale, a Sync diff that shows one design replacing another — offer to file it as an ADR. Offer when the choice had real alternatives and lasting consequences; don't file trivia (a variable rename is not a decision).

Either way, filing means: write `wiki/decisions/NNNN-slug.md`, add it to `index.md`'s Decisions section **with its status shown**, and append a `decision |` entry to `log.md`. Status changes later (proposed→accepted, accepted→superseded) update all three places and log again.

## index.md — Decisions section

`index.md` gains a `## Decisions` section listing every ADR: `[[NNNN-slug]] — one-line summary — *(status)*`. The status annotation is part of the index contract: a reader scanning the index must be able to see which decisions are settled without opening each file.

## log.md — decision prefix

`decision` joins the log prefix set:

```
## [YYYY-MM-DD] decision | ADR-NNNN <new | proposed→accepted | accepted→superseded (by NNNN)>
```

## Interaction with code-sync *(only if both modules are installed)*

The tracked repo is a source for *what the code does* — it is **not** an authority over `wiki/decisions/`. Concretely:

- **Sync never edits an ADR because of a code diff.** ADRs record human choices; a diff can't change what was decided, only reveal that reality has diverged from it.
- When a Sync diff **contradicts an accepted ADR** (the code now does the thing the ADR rejected), report it as **decision drift** in the Sync summary and stop there — the human rules on which side is wrong. If the human says the decision was in fact overturned, that's a superseding ADR (new file, old one marked superseded), not an edit to the old one. If the code is wrong, that's the human's to take to the code side; the wiki records the drift observation in the sync log entry either way.

## Lint additions

Lint's checklist gains:

- **ADR status consistency** — frontmatter `status` = the page's Status line = the `index.md` annotation, for every decision page.
- **Stale proposals** — ADRs sitting in `proposed` with no activity; surface them for a call (accept, supersede, or an explicit "still deliberately open").
- **Supersession completeness** — every `superseded` ADR points to its successor, and the entity pages affected by the overturned decision carry statement-level `⚠️ Superseded` markers citing the successor.
