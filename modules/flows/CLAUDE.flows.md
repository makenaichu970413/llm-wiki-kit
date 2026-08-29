---
kit_layer: module
module: flows
kit_version: 0.1.0
---

<!--
  Appended to core/CLAUDE.core.md by INIT.md when the human opts into the
  flows module (independent of every other module — see Step 0). Adds:
  the wiki/flows/ directory, the flow-page format (a Mermaid diagram + a
  step-by-step explanation), the "flow it" / "画流程图" trigger phrase, a
  `flow` log prefix, and Lint checks for flow-page cross-linking and
  staleness. Ships no scripts — this module is pure schema, same as
  decisions/roadmap/tickets.
-->

## Flows layout addendum

```
{{VAULT_NAME}}/
└── wiki/
    └── flows/         # end-to-end process/runtime flow diagrams (Mermaid + step-by-step explanations)
```

Flow pages document **how a specific process actually runs** — where it starts, what happens at each step, the order steps execute in, every decision point and where each branch goes, and where it ends — as a Mermaid diagram plus a step-by-step explanation. Different altitude from a category like `concepts/` (explains *what something is and why it matters*) or a single entity page describing one file/component in isolation: a flow page follows one runtime path across however many pieces it actually touches, and is verified against the real source — not a tidy-sounding paraphrase of it.

## Flow page format

Frontmatter uses the core page format (`type: flow`). Named with a descriptive slug, no numbering — topic-keyed like most entity categories, not chronological like `decisions/`/`tickets/`: `wiki/flows/<topic>-flow.md`.

Body skeleton — every flow page states:

- **一句话摘要 / One-line summary** — what process this diagrams, and its single entry point (what triggers it).
- **流程图 / Flow diagram** — a Mermaid `flowchart` code block covering every step, every decision diamond, every branch's destination, and where the flow ends. Built from the real source — `code_refs` cites the functions/files it was verified against *(code-sync only)*; without code-sync, cite whatever locator this vault's page format uses (a document section, a timestamp, a page number) — never a plausible-looking guess at control flow the source doesn't actually show.
- **逐步骤说明 / Step-by-step explanation** — one entry per diagram node: what happens, why this step exists, what happens next. Written so both a non-technical reader and someone technical can follow it (plain-language description + a citation, not two separate write-ups).
- **不明确 / Unclear** — anything the source doesn't establish clearly enough to diagram with confidence. Same rule as everywhere else in this wiki: never fill the gap with a guess — name it here instead, or park a real open question in `question.md` if it needs the human's input to resolve.
- Links to the entity pages this flow touches.

## When to create one — trigger phrase: "flow it" / "画流程图"

Two entry points, mirroring how answers get filed:

- Whenever analyzing a process for a Query produces a flowchart-with-explanation worth keeping — same bar as `wiki/answers/` (real cross-referencing, resolves something previously fuzzy/unconfirmed, likely to recur for a future session).
- **The human says "flow it" / "画流程图"** (or similar phrasing — a convention, not a parser), followed by the topic (e.g. "flow it: checkout retry logic"). Means: apply this section's full spec without the human needing to restate it — start point, every step in execution order, every decision point and where each branch goes, where it ends, a per-step what/why/next explanation legible to both a non-technical reader and someone technical, no fabricated logic, anything the source doesn't establish clearly flagged as **不明确 / Unclear** rather than guessed — then produce the Mermaid diagram + step-by-step explanation and file it under `wiki/flows/` per the format above.

## Interaction with the pages it touches

A flow page owns the step-by-step runtime description; the entity pages it touches get a **one-line pointer** back (e.g. under their own "Related" section) rather than re-describing the same sequence of steps in prose. If an entity page already has a prose walk-through of the same process when a flow page is created for it, fold that walk-through down to a pointer — don't maintain the same sequence in two places that can quietly drift apart.

## index.md — Flows section

`index.md` gains a `## Flows` section listing every flow page: `[[<topic>-flow]] — one-line summary of the process it covers`.

## log.md — flow prefix

`flow` joins the log prefix set:

```
## [YYYY-MM-DD] flow | <topic> — <created | updated | superseded>
```

## Interaction with code-sync *(only if both modules are installed)*

Same as any other page: `code_refs` maps a diff to the flow pages it might affect. If a diff changes a step, a branch condition, or an exit path the diagram already documents, update the diagram and flag the change with `⚠️ Superseded` per the core rule — a flow page is exactly as trustworthy as its least-checked step, same as everywhere else in this wiki. Sync never invents a flow page from a diff alone, the same way it never invents any other page from a guess — it updates an existing one, or flags that a new one looks warranted for the human to confirm.

## Interaction with decisions *(only if both modules are installed)*

When a branch or step in a flow exists **because of** an architectural choice (not just because that happens to be how it's currently built), the flow page can cite the ADR directly (`per [[NNNN-slug]]`) at that step — a one-line pointer, not a full workflow the way decisions↔roadmap gets one.

## Lint additions

Lint's checklist gains:

- **Flow-entity cross-link consistency** — every flow page is pointed to from at least one of the entity pages it documents (covered by the general orphan-page check, but worth calling out explicitly since a flow page with no inbound link is easy to lose track of).
- **Stale flows** *(code-sync only)* — a flow page's `synced_at_sha` older than a `code_refs` file's last real change is the same "claims older than their source citations" check every other page gets, but a stale flow diagram is a correctness bug (a branch that no longer exists, a step that's been removed) rather than just an outdated fact — worth flagging with higher priority than a stale prose claim.
