---
kit_layer: module
module: related-wikis
kit_version: 0.1.0
---

<!--
  Appended to core/CLAUDE.core.md by INIT.md when the human opts into the
  related-wikis module (independent of every other module — see Step 0). Adds:
  wiki/related-wikis.md, the cross-vault reference convention, the "link wiki"
  trigger phrase, a `link` log prefix, and a Lint check for stale related-vault
  paths. Ships no scripts — this module is pure schema.
-->

## Related-wikis layout addendum

```
{{VAULT_NAME}}/
└── wiki/
    └── related-wikis.md   # registry of sibling vaults + the boundary each owns
```

Some vaults aren't self-contained — a UI vault's subject matter runs into its API vault's subject matter at a well-defined seam (the API contract), a service vault runs into the platform vault it depends on, and so on. `related-wikis.md` records **which other vaults exist and what each one owns**, so the boundary is a decision made once and looked up, not re-litigated in every page that happens to touch it.

**Vaults stay independent. This module never merges them.** A related vault is a separate directory, a separate `git init`, a separate `CLAUDE.md` — this module only adds a registry and a citation convention, so two (or more) vaults covering adjacent territory can point at each other without either one owning or absorbing the other's content.

## Related-wikis page format

`wiki/related-wikis.md` uses `type: related-wikis` frontmatter. One entry per related vault:

```markdown
## <VaultName>

- **Path:** `<absolute path>` — or `planned, not yet initialized at <expected path>` if it doesn't exist yet.
- **Boundary:** what this vault owns vs. what `<VaultName>` owns, from this vault's side — e.g. "this vault documents UI components and what they call; `<VaultName>` documents the endpoint contracts they call."
```

**A related vault doesn't need to exist yet.** Same spirit as a `[[red link]]` inside a single vault — a forward reference to something not yet real isn't an error, it's a placeholder to fill in later. Register the relationship with a `planned` path the moment you know it's coming; update the entry with the real path once that vault is actually initialized.

## Cross-vault reference convention

`[[wikilinks]]` only resolve **within this vault** — Obsidian has no concept of a link crossing into a different vault folder, and this kit's own Lint red-link scan only ever looks inside one vault too. So a reference to a page in a related vault is written as plain text, never a wikilink, anywhere in this wiki:

```
→ related: <VaultName> — wiki/<page-path>.md
```

e.g. `This component calls the users endpoint (→ related: api-wiki — wiki/apis/users-endpoint.md).` This is deliberately unambiguous with `[[wikilinks]]` so Lint's red-link/orphan scan never mistakes one for the other.

**Read-only in both directions.** This vault may cite a related vault's page. It never edits one — the same boundary this kit already holds for a tracked code repo (a source, read from, never written to) applies here too: a related vault is another vault's own territory.

## Registering a related vault — trigger phrase: "link wiki"

Two entry points:

- **During Init**, if the human already named a related vault in the Interview, the entry is seeded directly (see `INIT.md`).
- **Later, any time** — the human says **"link wiki"** (or similar phrasing — a convention, not a parser): ask for the vault's name, its path (or "planned" if it doesn't exist yet), and a one-line boundary description; write or update the entry in `wiki/related-wikis.md`, update `index.md`'s Related Wikis section, and append a `link |` entry to `log.md`. Also use this to promote a `planned` entry to a real path once that vault actually gets initialized — same trigger phrase, not a separate one.

## Query workflow addition

Before parking an unanswerable question in `question.md` (see core's Query section), check whether its topic falls inside a registered related vault's boundary. If it does, say so and point at that vault instead of parking the question here — a question that belongs to another vault's territory isn't this vault's open question.

## Interaction with decisions *(only if the decisions module is also installed)*

If keeping vaults separate (or, later, merging them) was itself a deliberate call — weighing one combined vault against separate vaults connected by reference — that's exactly the kind of choice the decisions module exists for. File it as an ADR (`wiki/decisions/`) and cite it from the relevant `related-wikis.md` entry, rather than leaving the reasoning implicit in the registry.

## index.md — Related Wikis section

`index.md` gains a `## Related Wikis` section listing every registered vault: `<VaultName> — <path or "planned"> — <one-line boundary>`.

## log.md — link prefix

`link` joins the log prefix set:

```
## [YYYY-MM-DD] link | <VaultName> <registered | path updated | boundary updated>
```

## Lint additions

Lint's checklist gains:

- **Stale related-vault paths** — for every entry with a real (non-`planned`) path, confirm the directory still exists. A related vault that's been moved or deleted doesn't erase its own history elsewhere, but this vault's pointer to it needs correcting or re-flagging.
- **Long-planned entries** — a `planned` entry that's sat unresolved a long time is worth surfacing the same way a stale ADR proposal is (see decisions module, if installed) — not an error, just worth a nudge.
