---
kit_layer: module
module: tickets
kit_version: 0.1.0
---

<!--
  Appended to core/CLAUDE.core.md by INIT.md when the human opts into the
  tickets module (independent of every other module — see Step 0). Adds:
  wiki/tickets/ (one file per ticket), wiki/board.md (a kanban board formatted
  for Obsidian's community "Kanban" plugin), the "create ticket" / "move
  ticket ... to ..." trigger phrases, a `ticket` log prefix, and a Lint check
  that every ticket's frontmatter status matches its column on the board.
  Ships no scripts — this module is pure schema, same as decisions/roadmap.
-->

## Tickets layout addendum

```
{{VAULT_NAME}}/
└── wiki/
    ├── tickets/        # one file per ticket — day-to-day work items
    └── board.md        # the kanban board: Backlog / In Development / In Review / Resolved
```

Tickets are the **operational, day-to-day layer** — a unit of work small enough to move across a board in one sitting. This is a different altitude from `wiki/plan.md` (roadmap module, if installed), which records the human's committed phases and stories, and from `wiki/decisions/` (decisions module, if installed), which records *why* a choice was made. A ticket can implement a story, or follow from a decision, but it isn't either of those — see the interaction sections below.

## Ticket page format

Frontmatter adds a `status` field to the core page format (`type: ticket`):

```yaml
---
type: ticket
status: backlog | in-development | in-review | resolved
tags: [...]
updated: YYYY-MM-DD
---
```

One ticket per file, named `{{TICKET_PREFIX}}-NNNN-short-slug.md` (e.g. `TICKET-0007-fix-login-timeout.md`), numbered in creation order starting at `0001`. `{{TICKET_PREFIX}}` is decided once per vault during Init (any short uppercase code the human picks — a generic `TICKET`, a Jira-style project code, whatever fits). Numbers are never reused, even once a ticket is resolved or dropped — same rule as decisions' ADR numbering.

Body skeleton — every ticket page states:

- **Status** — one line mirroring the frontmatter (`in development`) — frontmatter, this line, and the card's column in `board.md` must always agree; Lint checks this three-way.
- **Summary** — one or two sentences: what needs to happen and why.
- **Notes** — free-form, grows as work happens (context, findings, why a call was made). If a ticket is closed without actually shipping (duplicate, out of scope, superseded by another ticket), it still moves to **Resolved** — there's no separate "won't fix" column — but Notes must say why, so the board never quietly loses it.
- Links to the entity pages, decisions, and plan stories this ticket relates to.

## Board format

`wiki/board.md` is one file, written for Obsidian's community **"Kanban"** plugin (author: mgmeyers). Init seeds it empty from this module's template:

```markdown
---
kanban-plugin: board
type: board
tags: [tickets]
updated: YYYY-MM-DD
---

## Backlog


## In Development


## In Review


## Resolved

```

Each column is a `##` heading; each card is a list item linking to that ticket's file, with a display alias so the card reads cleanly without opening it:

```markdown
- [ ] [[TICKET-0007-fix-login-timeout|TICKET-0007 — Fix login timeout]]
```

**This is a soft dependency, not a hard one.** With the Kanban plugin installed, opening `board.md` in Obsidian renders an actual drag-and-drop board. Without it, the file is still fully readable and editable as plain markdown — headings and a linked list under each. If the plugin doesn't recognize the file on first open (its settings-block format can shift between plugin versions), don't hand-author a fix — open the plugin's own "new board" UI once and let it rewrite `board.md` into its current canonical format; the column names and card links are what this schema depends on, not the trailing settings block byte-for-byte.

## Creating and moving tickets

**"create ticket \<title\>"** (or similar phrasing — a convention, not a parser): draft `wiki/tickets/{{TICKET_PREFIX}}-NNNN-slug.md` (next number, status `backlog`), add its card to the bottom of the Backlog column in `board.md`, update `index.md`, and append a `ticket |` entry to `log.md`.

**"move ticket \<id\> to \<column\>"**: update the ticket file's frontmatter `status` and Status line, cut the card from its current column and paste it into the new one in `board.md`, and log it. Movement isn't strictly linear — a card can go back from In Review to In Development, for instance.

**Moving is mechanical on the human's word — no separate approval gate**, for any column including Resolved. This is a deliberate contrast with decisions/roadmap, where only the human promotes status: tickets are the operational layer, not architectural commitments, so acting on "move TICKET-0007 to in review" the moment it's said is the expected posture, not a shortcut.

## index.md — Tickets section

`index.md` gains a `## Tickets` section, but unlike Decisions it does **not** enumerate every ticket — it's a single pointer line: `see [[board]] for live status`. `board.md` already is the current-state index for tickets, kept correct by every move; listing tickets a second time in `index.md` would just be a second place for that list to go stale, and tickets churn far more than ADRs do.

## log.md — ticket prefix

`ticket` joins the log prefix set:

```
## [YYYY-MM-DD] ticket | {{TICKET_PREFIX}}-NNNN <created | backlog→in-development | in-development→in-review | in-review→resolved | ...>
```

## Interaction with roadmap *(only if the roadmap module is also installed)*

Tickets and the plan stay independent — neither owns the other, and nothing here auto-updates either file. They cross-reference in plain text, since a `plan.md` story isn't its own file (no wikilink target to point at): a ticket's Notes/Links can say `implements S2.3 (see [[plan]])`, and a story's line can say `tracked as {{TICKET_PREFIX}}-0007`. If a whole phase or story is really just a stack of tickets, that's a scope observation worth a chat with the human — not something to restructure silently on either side.

## Interaction with decisions *(only if the decisions module is also installed)*

A ticket that's downstream of an architectural choice can cite the ADR directly (`per [[NNNN-slug]]`) in its Notes — a one-line pointer, not a full workflow the way decisions↔roadmap gets one.

## Lint additions

Lint's checklist gains:

- **Board/frontmatter consistency** — every ticket's frontmatter `status` matches the column its card sits under in `board.md`, three-way with the page's own Status line. Every ticket file has exactly one card somewhere on the board (no ticket missing from the board, no card pointing at a deleted or renamed file).
- **Stale in-review** — tickets sitting in In Review a long time with no activity, worth a nudge for a call (approve, send back, or an explicit "still deliberately open") — informational, same posture as decisions' stale-proposal check, not a gate.
