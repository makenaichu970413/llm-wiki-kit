---
kit_layer: module
module: roadmap
kit_version: 0.1.0
---

<!--
  Appended to core/CLAUDE.core.md by INIT.md when the human opts into the
  roadmap module (independent of every other module — see Step 0). Adds:
  wiki/plan.md (from this module's template), the plan-maintenance rules,
  the plan log-prefix, and Lint checks for plan hygiene. Ships no scripts —
  this module is pure schema.
-->

## Roadmap layout addendum

```
{{VAULT_NAME}}/
└── wiki/
    └── plan.md        # the plan: phases, stories, dependencies, acceptance criteria
```

`plan.md` is the single authoritative statement of **what happens next and in what order** — phases, stories, dependencies, acceptance criteria, and the gates between them. One file, at the wiki root next to `overview.md`; if it ever outgrows one file, splitting is a schema change to propose to the human, not something to do silently.

**The plan is prescriptive — it belongs to the human.** Everything else in the wiki describes what *is*; `plan.md` records what the human has *committed to do*. You keep it tidy, propose updates, and record progress — but structural changes (adding/removing/reordering phases or stories, changing scope or acceptance criteria) and completion calls are the human's to approve. Never restructure the plan silently.

## Plan format

`plan.md` uses `type: plan` frontmatter and this shape (the Init template seeds it):

- **Milestones** *(optional)* — a short table naming the big outcomes and which phases deliver them.
- **Phases** — `## Phase N — <name>`, each containing stories as checkboxes:

  ```markdown
  - [ ] **S2.1 <story title>** (size, depends on S1.3) — what it is, and the
    acceptance criterion that decides "done".
  ```

  Story IDs (`S<phase>.<n>`) are stable handles — other wiki pages and log entries refer to them, so don't renumber existing stories when inserting new ones (append `S2.4`, or suffix `S2.3.1` for a sub-story).
- **Exit condition** — one line per phase stating what must be true before the next phase starts. A phase's exit condition is a gate, not a summary — check it before proposing work from the next phase.

## Progress discipline

- **Ticking a box requires evidence.** When a story completes, the checkbox flips **and** the story line gains a short completion note — when, and where the result lives (a path, a commit, a wiki page). "Done" with no pointer is how plans rot.
- **Scope changes are edits, not comments.** When a story's scope shrinks or grows, edit the story text (with a `⚠️ Superseded` blockquote if it reverses something previously stated) rather than piling clarifications underneath.
- Anything that changes the plan's structure or marks a story complete gets a `plan |` log entry. Checkbox-only progress notes and typo fixes don't.

## log.md — plan prefix

`plan` joins the log prefix set:

```
## [YYYY-MM-DD] plan | <what changed: story added/completed, phase reworked, gate decision>
```

## Interaction with code-sync *(only if both modules are installed)*

The tracked repo shows what *happened*; the plan says what was *committed to*. Sync connects them in one direction only:

- **Sync never restructures `plan.md` from a diff.** No adding, removing, or rescoping stories because of what the code did.
- When a Sync diff **looks like a story landing** (commits that plainly implement `S2.3`), say so in the Sync summary and **propose** ticking the box with the evidence note — the human confirms completion; the diff alone doesn't.
- When a diff shows work that **contradicts the plan** (something built that the plan defers or excludes), report it as plan drift, same posture as any other contradiction: surface it, let the human rule — update the plan, or flag the code side.

## Interaction with decisions *(only if both modules are installed)*

When a plan change is downstream of an architectural choice — a phase reordered because an approach was picked, a story cut because an option was rejected — **the ADR comes first**: file/update the decision in `wiki/decisions/`, then edit `plan.md` citing it (`per [[NNNN-slug]]`). Link both ways: the ADR's links section includes the plan items it affects. The plan states *what and when*; the ADR holds the *why* — don't bury rationale in a story line where the next reader can't find it.

## Lint additions

Lint's checklist gains:

- **Gates vs reality** — phases whose exit conditions all read as satisfied but which are still marked open (or the reverse: next-phase stories in progress while the previous gate is unmet).
- **Evidence-free completions** — checked stories with no completion note.
- **Stale plan** — `log.md` or entity pages describing work the plan doesn't reflect (a story that clearly happened but was never ticked, or vice versa).
