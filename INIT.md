# INIT.md — new vault initialization script

You are an LLM setting up a brand-new LLM Wiki vault from this kit. The human has copied (or cloned) this `llm-wiki-kit/` folder into a new empty directory and opened it in Claude Code, and asked you to initialize it per this file. Follow the steps below **in order**. Each step has an explicit completion criterion — don't move to the next step until the current one's criterion is met.

Do not skip the Interview by guessing answers yourself. The whole point of this script is that a human who has never read `PLAN.md` (the kit's own design rationale, not needed at runtime) can get a well-fitted vault out of a short conversation.

**How to ask (applies to Step 0 and Step 1):** if the environment provides an interactive question tool (in Claude Code: `AskUserQuestion`, which renders clickable option cards), use it for the closed-choice questions — yes/no, pick-one, multi-select confirmations — and batch related choices into one card round rather than asking one at a time. Ask open-ended questions (free text: the project description, filesystem paths) in plain chat; a card's "Other" box is a poor place to type a paragraph or paste a path. Mind the tool's limits (max 4 questions per call, max 4 options per question) — if a proposal doesn't fit, split it across two rounds or drop that question back to chat. If no such tool is available, ask everything conversationally in chat — the interview works either way.

---

## Step 0 — Module selection

Ask: **"Does this wiki track a git code repository?"** *(closed choice — question tool if available: two options, each with a one-line description of what gets installed)*

- **Yes** → install the `code-sync` module (Bootstrap + Sync workflows, `wiki-state.json`, `scripts/`). Continue to Step 1 with the code-sync-tagged questions included.
- **No** (a reading project, a research topic, personal notes, anything without a git repo as the primary source) → core only. The wiki's only way to receive new source material is the Ingest workflow (human drops docs into `raw/`). Continue to Step 1, skipping code-sync-tagged questions.

*(If this kit ever grows a second module, this becomes a checklist instead of a single yes/no — not yet.)*

**Done when:** you know which modules to assemble.

---

## Step 1 — Interview

Ask these in conversation, not as a wall of questions at once — a natural back-and-forth is fine. Mixed mode per "How to ask" above: #1 and the path half of #4 are open-ended — ask them in chat first; #2, #3, #5 and the branch half of #4 are choices — batch them into one card round once the chat answers are in. Record the answers; you'll use them in Step 2.

1. **"One paragraph: what is this vault about?"** → `{{PROJECT_DESCRIPTION}}` / `{{PROJECT_NAME}}`.
2. **"What are the 'entities' in this domain?"** — Don't just ask; **propose first**. Scan the source material (directory tree for a code repo, a table of contents / sample chapter for a document collection, whatever's available) and suggest categories, e.g.:
   - Data engineering repo → `pipelines/`, `tables/`, `concepts/`, `domains/`
   - Web app → `services/`, `apis/`, `components/`, `concepts/`
   - Book / research topic → `characters/`, `themes/`, `chapters/`, `concepts/`
   Get human confirmation or correction. *(Question tool: present the proposed categories as multi-select options — the human ticks what to keep and adds extras via "Other". More than 4 proposals → split across two rounds, or fall back to chat for this question.)* → `{{ENTITY_CATEGORIES}}`. For each category, also agree on a **page template** (the "must state" checklist — e.g. a pipeline page states purpose/inputs/outputs/schedule/known issues) → `{{PAGE_TEMPLATES}}`.
3. **"What language should the wiki be written in?"** — Default proposal: follow the source material's own language (code comments, docs). Note conversation language and storage language are independent — confirm the human understands they can ask in their own language regardless of what the wiki is written in. *(Question tool: make "follow the source material's language" the recommended option.)* → `{{LANGUAGE_CONVENTION}}`.
4. *(code-sync only)* **"What's the project repo's absolute path?"** — ask in chat, and include an example so the human knows the expected shape (Windows: `D:\Programming\shop-api`; macOS/Linux: `/Users/anna/dev/shop-api`). Don't assume the vault is a sibling directory of the repo — ask, don't infer. → `{{PROJECT_REPO_PATH}}`. Then get `{{MAIN_BRANCH}}` **without making the human type it**: run `git -C <path> branch --list` (or `branch -r` if local branches look incomplete) and present the real branches as options, recommending the repo's default branch — a picked branch can't be a typo.
5. *(code-sync only)* **"Any known commit-noise patterns I should skip during Sync?"** — always give concrete examples so the human knows what counts as noise: a `[CHECK]`/`chore:`/`[skip ci]` prefix convention, automated version-bump or dependency-update commits, formatting-only commits. *(Question tool: make "don't know yet — refine after the first few real Syncs" the recommended option, plus an "I have some" option whose patterns arrive via "Other".)* If the human doesn't know yet, say that's fine. → `{{SYNC_TRIAGE_RULES}}` (may start empty).

**Done when:** every `{{PLACEHOLDER}}` referenced in Step 2 below has an answer (or an explicit "leave empty, fill in later" for #5).

---

## Step 2 — Assemble and instantiate

1. Create the new vault's directory structure:
   ```
   <vault>/
   ├── CLAUDE.md          # assembled below
   ├── .gitignore         # copy from core/.gitignore
   ├── raw/
   │   └── assets/
   └── wiki/
       ├── index.md       # from core/wiki/index.md, placeholders filled
       ├── log.md         # from core/wiki/log.md, placeholders filled
       ├── overview.md    # write fresh — a one-pager using the Step 1 answers
       ├── sources/
       ├── answers/
       └── <one dir per entity category from Step 1, question 2>/
   ```
   *(code-sync only, additionally)*
   ```
   ├── wiki-state.json    # from modules/code-sync/wiki-state.json, placeholders filled
   └── scripts/
       ├── sync.ps1       # copy from modules/code-sync/scripts/sync.ps1 verbatim
       └── sync.sh        # copy from modules/code-sync/scripts/sync.sh verbatim
   ```
2. Assemble `CLAUDE.md`: take `core/CLAUDE.core.md`, replace every `{{PLACEHOLDER}}` with the Step 1 answers. *(code-sync only)* append `modules/code-sync/CLAUDE.code-sync.md`'s content (with its own placeholders filled) into the appropriate places — the "Code-sync layout addendum" merges into the Layout section, "Bootstrap"/"Sync" workflows join the "Core workflows" section, and the log-prefix note extends `log.md`'s prefix list. The result is **one self-contained `CLAUDE.md`** — write it over the kit's placeholder `CLAUDE.md` at the vault root; nothing in the running vault should reference back to `llm-wiki-kit/` at runtime.
3. Remove every HTML comment (`<!-- ... -->`) from the assembled file — those are Init-time guidance, not part of the operating schema.
4. **Delete the kit's own scaffolding from the vault directory** — the vault is initialized in-place inside the copied kit folder, and everything that only served Init must go so the vault ends up self-contained:
   - `core/`, `modules/`, `examples/`, `INIT.md`, `IDEA.md`, `README.md`, `CHANGELOG.md`
   - If the kit was **cloned** rather than copied (there's a `.git/` carrying the kit's own history), delete that `.git/` too, so the next step's `git init` starts the vault's history fresh.
   - Keep `.obsidian/` if present (it's the human's local Obsidian config, harmless) and the `.gitignore` you already instantiated from `core/.gitignore`.
   - Yes, this deletes `INIT.md` itself mid-run — that's fine: you've already read it, and Steps 3–5 are in your context. Don't defer the cleanup to "after everything else"; it must happen before `git init` so no kit file ever enters the vault's history.
5. `git init` the new vault; write the `log.md` init entry (already templated in `core/wiki/log.md`, just fill placeholders); make the initial commit.

**Done when:** the vault directory exists, `CLAUDE.md` is one self-contained file, no kit scaffolding files remain, and there's an initial git commit that contains only vault files.

---

## Step 3 — Self-check

1. Grep the assembled `CLAUDE.md` and every templated file for a literal `{{` — **zero** should remain. If any are left, you missed a Step 1 answer; go back and ask.
2. *(code-sync only)* Confirm `wiki-state.json → project_repo` points at a real, existing git repository (`git -C <path> rev-parse HEAD` should succeed) and `branch` is a real branch. Run `scripts/sync.ps1` (or `.sh`) once as a dry run — it should print "last_synced_sha is null - run the Bootstrap workflow first" and exit cleanly, not error out.
3. Read the assembled `CLAUDE.md` once, start to finish, as if you were a fresh session with no memory of this Init conversation — does it read as a complete, coherent schema on its own? If something only makes sense with Init-conversation context, fix it now.
4. List the vault root (including hidden files) — none of the kit's scaffolding may remain (`core/`, `modules/`, `examples/`, `INIT.md`, `IDEA.md`, `README.md`, `CHANGELOG.md`), and `git log` should show only the vault's own initial commit, no kit history.

**Done when:** all four checks pass.

---

## Step 4 — Register the vault in the user-global CLAUDE.md

A vault only pays off if future sessions **in the project** know it exists — and those sessions never read the vault's own `CLAUDE.md`. The pointer has to live in the user-global `~/.claude/CLAUDE.md` (Windows: `C:\Users\<name>\.claude\CLAUDE.md`), which Claude Code loads in every session regardless of working directory.

1. *(code-sync)* Draft an entry from the template below, filled with the Step 1 answers. If the global file already has entries for other wikis, match their wording and structure instead of the template — consistency beats the template.

   ```markdown
   ## {{PROJECT_NAME}} — external LLM wiki

   The `{{PROJECT_NAME}}` project (<one-line description>; repo at
   `{{PROJECT_REPO_PATH}}`, tracked branch `{{MAIN_BRANCH}}`) has a companion
   knowledge wiki in a separate repo: `<absolute vault path>`.

   When working in `{{PROJECT_NAME}}` (dev work, code review, or questions about
   architecture, known issues, past decisions, or design rationale), check the
   wiki before re-deriving the answer from scratch:
   1. Read `<vault path>\wiki\index.md` to see what's documented.
   2. Open the relevant page(s) — code-verified findings with `file:line`
      citations; `synced_at_sha` frontmatter shows what commit each claim was
      last checked against.
   3. Only fall back to exploring the source directly if the wiki doesn't
      cover it, or a claim needs re-verification.
   4. The wiki's maintenance workflows are defined in `<vault path>\CLAUDE.md`
      — only follow those when explicitly asked to maintain the wiki. After
      project commits land, `scripts\sync.ps1` / `scripts/sync.sh` (run from
      the vault) does the incremental update.
   ```

2. Show the human the drafted entry and **get confirmation before writing** — this edits a file outside the vault. Then append it to the user-global `CLAUDE.md` (create the file with a `# Global notes` heading if it doesn't exist yet).
3. *(pure core)* There's no project repo whose sessions would trigger the pointer, so this step is usually skipped. Ask the human whether there's some other working directory where they'd want the reminder (e.g. the folder of a writing project this vault supports) — if yes, register the same way with the wording adapted; if no, skip.

**Done when:** the entry is written to the user-global `CLAUDE.md` and confirmed by the human — or the human explicitly declined / pure-core skip applies.

---

## Step 5 — Handoff

Tell the human what happens next, matched to the module chosen in Step 0:

- **code-sync installed:** "Vault is ready. Next: run the Bootstrap workflow — I'll scan `{{PROJECT_REPO_PATH}}`'s directory tree first (structure pass, no file contents), propose a batch breakdown for reading it in chunks, then read + write pages batch by batch. Say 'run bootstrap' when ready."
- **pure core:** "Vault is ready. Next: ingest your first source — drop a document into `raw/` and tell me to process it."

Also surface these as standing user-facing notes (gotchas that bite people, not obvious from reading the schema):

- **Obsidian graph view trap** (if the human is using Obsidian to browse): clicking a *grey* (unresolved-link) node in the graph view instantly creates a 0-byte file at the vault root under that name, and that empty file will then win over the red link when a real page is later created for that name. Either turn off "Unresolved links" in the graph filters, or just don't click grey nodes — only click solid ones, and let the LLM create pages.
- **Red links are TODO markers, not errors.** A `[[wikilink]]` to a page that doesn't exist yet is expected and fine — it becomes real when enough context accumulates to justify the page (the Lint workflow's "≥3 mentions" heuristic is the trigger, not "first mention").
- *(code-sync only)* **`git fetch` can hang or fail silently** (credential prompts, flaky network) — `sync.ps1`/`sync.sh` already handle this by falling back to the locally-cached `origin/<branch>` ref with a warning, but if a sync run looks stale, check whether fetch actually succeeded before trusting the diff.
