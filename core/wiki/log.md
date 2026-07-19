---
type: log
---

# Log

> Append-only — entries are never deleted or rewritten. Prefix format: `## [YYYY-MM-DD] <op> | <subject>` where op ∈ init | ingest | query | lint (add bootstrap | sync if the code-sync module is installed).
> Last 5 entries: `grep "^## \[" log.md | tail -5`
> Before writing a new entry, grep headers rather than reading the whole file — skip the body of any header tagged `⚠️ Archived <date>` unless this task needs that entry's detail. See CLAUDE.md's log.md / Lint sections for the tagging rule.

## [{{INIT_DATE}}] init | vault created
Schema (CLAUDE.md), directory skeleton, index/log templates{{CODE_SYNC_INIT_NOTE}} created via Init. {{NEXT_STEP_NOTE}}
