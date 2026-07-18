---
type: log
---

# Log

> Append-only. Prefix format: `## [YYYY-MM-DD] <op> | <subject>` where op ∈ init | ingest | query | lint (add bootstrap | sync if the code-sync module is installed).
> Last 5 entries: `grep "^## \[" log.md | tail -5`

## [{{INIT_DATE}}] init | vault created
Schema (CLAUDE.md), directory skeleton, index/log templates{{CODE_SYNC_INIT_NOTE}} created via Init. {{NEXT_STEP_NOTE}}
