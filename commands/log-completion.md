---
description: Log one shipped completion (hive asset, workflow, project, bug fix, etc.) into the user's portfolio completions ledger. Daily entry + INDEX append.
---

# /log-completion

Log a single shipped completion to `~/projects/project-portfolio/portfolios/will/completions/`.

Argument: `$ARGUMENTS` is the kebab-case slug (e.g. `session-transcript-mirror`). If empty, ask for it.

## Steps

1. **Resolve slug.** Read `$ARGUMENTS`. If empty, use AskUserQuestion to ask:
   - "Slug for this completion? (kebab-case, e.g. session-transcript-mirror)"
   Validate it matches `^[a-z0-9][a-z0-9-]*$`. Re-ask if not.

2. **Resolve today.** Run `date +%Y-%m-%d` via Bash. Store as `TODAY`.

3. **Ensure day folder.** Run `mkdir -p ~/projects/project-portfolio/portfolios/will/completions/$TODAY`.

4. **Check no clobber.** If `~/projects/project-portfolio/portfolios/will/completions/$TODAY/<slug>.md` exists, ask if the user wants to overwrite. If no, stop.

5. **Collect fields.** Use AskUserQuestion (one batch, multiple questions):
   - Title (human-readable)
   - Type — multiSelect=false, options: hive-asset, workflow, custom-flow, project, bug-fix, infrastructure, content
   - What — one paragraph summary
   - Why — one paragraph problem it solved
   - Artifacts — newline-separated list of paths / URLs / commits
   - hive_slug — registered slug in REGISTRY.yaml, or "none"
   - asset_path — absolute path to the asset, or "none"

6. **Normalize.** Convert "none" to `null` for `hive_slug` and `asset_path`. Split Artifacts on newlines, strip blanks, prefix each with `- `.

7. **Write the entry.** Use Write to create `~/projects/project-portfolio/portfolios/will/completions/$TODAY/<slug>.md`:

   ```
   ---
   slug: <slug>
   title: <title>
   type: <type>
   shipped: <TODAY>
   hive_slug: <hive_slug or null>
   asset_path: <asset_path or null>
   links:
   <indented artifact list, two spaces + "- ">
   ---

   # <title>

   ## What
   <what paragraph>

   ## Why
   <why paragraph>

   ## Artifacts
   <bulleted artifact list>

   ## Hive registered
   <"yes" if hive_slug != null else "no">
   ```

8. **Append INDEX.** Path: `~/projects/project-portfolio/portfolios/will/completions/INDEX.md`.
   - If it doesn't exist, create it with:
     ```
     # Completions Index

     Running ledger of every shipped completion. Newest entries appended at the bottom. Weekly rollups under `_weekly/`.

     | Date | Slug | Type | Title | Asset |
     |------|------|------|-------|-------|
     ```
   - Append one row: `| <TODAY> | <slug> | <type> | <title> | <asset_path or —> |`

9. **Confirm.** Output exactly one line: `Logged: <TODAY>/<slug>.md — <title> (<type>)`

## Voice rules

No filler. No "I'll now...". Just do the steps. Banned words: leverage, drive, empower, synergize, robust, scalable, innovative, seamless. Use verbs that do work (Wrote, Appended, Logged).

## Notes

- Slug is the filename stem — don't add `.md` to `$ARGUMENTS`.
- If the user supplies the slug as arg, skip step 1's question but still validate the pattern.
- Day folder is idempotent — `mkdir -p` is safe.
- INDEX rows are append-only; never rewrite existing rows here. Weekly rollup reads this file.
