---
description: Launch-and-go mode. Runs the 10-item pre-flight checklist, stamps the per-project bug log, orchestrates subagent-driven execution, and optionally hands off to /supervisor for overnight. Required before T0 on any project extending a legacy pipeline or ingesting a new corpus.
---

# /launch-and-go — Launch-and-Go Mode

You are entering **Launch-and-Go Mode.** the user's standing rule (2026-05-23):

> **"It's supposed to be launch and go, not launch and debug for two days."**

This command exists because the niche-topic Release 2 ingest burned two days on 22 bugs that were latent in a pipeline nobody had stress-tested before the first real tick. Every single one of those bugs was detectable before T0. This command runs that detection.

Invoke `/launch-and-go <project-name>` when:
- Extending a legacy pipeline to a new corpus, new release, or new document kind
- Ingesting a new dataset against an existing worker/supervisor/dispatcher stack
- Wiring a new project that reuses prior-session infrastructure

If the project has no spec yet, stop here and invoke `/spec-code` first. This command assumes a spec exists. It does NOT replace `/spec-code` — it follows it.

---

## HARD RULES (non-negotiable)

### Rule 1 — Pre-flight is a HARD GATE. Not a suggestion.

All 10 pre-flight items (Phase 1) must pass before the first real ingest tick. If any item fails, the correct response is to fix the gap, not to proceed with the remaining items. A partial pass is a fail.

### Rule 2 — Every bug gets logged BEFORE moving on.

When a bug surfaces during execution, open the per-project `_BUGS.README.md` and add the entry before writing a single line of fix code. If you find yourself fixing bugs without logging them, you are building the next R2 situation.

### Rule 3 — Mirror bugs to lessons_learned.md.

Bugs that expose architectural gaps (not one-off typos) go to `~/.claude/memory-ledger/lessons_learned.md` as well as the per-project log. The hive needs to know.

### Rule 4 — Absolute paths in every subprocess.

No bare `uv`, `claude`, `ffmpeg`, `whisper`, or `python` in subprocess calls. Use `_resolve_<bin>_bin()` helpers or hardcoded absolute paths. Bare binaries work in your shell and break in cron, SSH non-login, and systemd. The niche-topic R2 build hit this on day 1 (B7).

### Rule 5 — Atomic claims only when MAX_PARALLEL > 1.

If any worker pool parallelism exists, the claim step must be a single atomic `UPDATE ... WHERE ... = (SELECT ... LIMIT 1) RETURNING *`. Two-statement SELECT+UPDATE is a race. The R2 build burned attempts on five parallel workers racing the same row (B17).

### Rule 6 — Tests never write to production paths.

Every test that touches a filesystem path uses `tmp_path` fixtures or equivalent isolation. Autouse fixture that patches `DB_ROOT` / any corpus root. `grep -rn "~/data\|~/studio" tests/` must return 0. The R2 build had stray test fixtures polluting `DB_ROOT` (B11).

### Rule 7 — Worker output behavior must be validated against schema constraints BEFORE corpus-wide ingest.

Run a 5-file dry-run. Confirm the longest expected quote, citation count, and page range all pass Pydantic validation. If the worker is capable of emitting output that violates the schema (e.g. a 247-char quote against a 200-char constraint), fix the schema or the prompt before T0. The R2 build hit B12 corpus-wide because nobody ran the dry-run.

### Rule 8 — Dispatcher coverage is required for every kind in the manifest.

Before T0: `grep "^def dispatch_" src/dispatcher.py` and compare against `jq '[.[].kind] | unique' manifest.json`. A missing dispatcher means the supervisor silently skips or errors on every file of that kind. The R2 build's single most expensive bug (ARCH-1) was missing video/audio dispatchers.

### Rule 9 — EXIT code semantics: race-lose must not look like real failure.

Race-lose (lost the atomic claim to another worker) gets its own exit code. It does NOT share code with `EXIT_GENERIC_ERROR`. If the caller cannot distinguish "I lost the race" from "I crashed," attempts burn toward the failure threshold for rows that are perfectly fine. The R2 build hit this with B9.

### Rule 10 — `extraction/text.md` is a fixed-name contract. Dispatcher post-worker backfill is mandatory.

Audit gates expect `extraction/text.md`. Worker prompts produce kind-specific names (`transcript.md`, `scenes.md`). The dispatcher is responsible for the backfill symlink or copy after the subprocess completes successfully. The R2 build hit this twice (B14, B20).

### Rule 11 — `case_id.py` patterns rot. Audit the manifest before the first ingest.

Take the first 10 filenames from the manifest, run `case_id.resolve_case_id(stem)` on each, and confirm all return non-MISC. New agencies, new naming conventions, new underscore-vs-hyphen conventions — each one is a new pattern gap. The R2 build had 50+ files binned as MISC on day 1 (B10, B18).

### Rule 12 — Never assume a named entrypoint does what its name implies.

Read `__main__` end-to-end before assuming a script runs the full pipeline. The R2 build assumed `triage.py` enqueued rows. It only wrote a JSON file. R1 had been bootstrapped manually and nobody documented that. Two days traced back partly to this assumption (B8).

---

## Phase 0 — Bootstrap (mandatory before any work)

In parallel, before touching any project code:

1. **Verify NAS mounts:**
   ```bash
   findmnt ~/studio && findmnt ~/data
   ```
   Both must return NFS-type mounts. If either is missing, stop.

2. **Read the project spec:**
   - `README.md` in the project folder
   - If no README or no spec section → invoke `/spec-code` first. Do not continue.

3. **Read the project's existing `_BUGS.README.md`** (if this is an extension of a prior release, the bug log may already exist):
   ```bash
   ls ~/projects/<project-name>/_BUGS.README.md 2>/dev/null \
     || echo "No bug log yet — will stamp in Phase 2"
   ```

4. **Read lessons_learned.md** — inherit every lesson from the ecosystem. Pay specific attention to lessons tagged with the same pipeline type (PDF ingestion, video ingestion, SQLite queue, subprocess workers, parallel claim patterns):
   ```
   ~/.claude/memory-ledger/lessons_learned.md
   ```

5. **Confirm the pre-flight canonical is accessible:**
   ```bash
   ls ~/projects/_template/PREFLIGHT.README.md
   ```

If any of these steps fail, HALT with the specific path that broke. Do not proceed.

---

## Phase 1 — Pre-flight Checklist (HARD GATE — must pass before T0)

This is the gate. Every item below is mandatory. Failure on any single item halts the launch. Document each result in the project `_BUGS.README.md` under "Pre-flight log."

For full expansion of each item (exact commands, pass/fail criteria, failure responses), see:
`~/projects/_template/PREFLIGHT.README.md`

**Checklist — run in this order:**

- [ ] **1. Manifest dimension audit** — What kinds are in this release's manifest?
  ```bash
  jq '[.[].kind] | unique' <manifest.json>
  ```
  Pass: a clean array of known kinds. Fail: `null`, unexpected kinds, or empty array.

- [ ] **2. Dispatcher coverage** — For each kind in the manifest, does `dispatch_<kind>_worker` exist?
  ```bash
  grep "^def dispatch_" src/dispatcher.py
  ```
  Cross-reference every kind from item 1. Any missing dispatcher is a HALT.

- [ ] **3. Worker prompt coverage** — For each kind, does `worker_<kind>.md` exist in the prompts directory?
  ```bash
  ls docs/prompts/worker_*.md 2>/dev/null || ls worker_*.md
  ```
  Cross-reference every kind. A missing worker prompt is a HALT.

- [ ] **4. case_id pattern coverage** — For the first 10 filenames in the manifest, does `case_id.resolve_case_id(stem)` return non-MISC?
  ```bash
  python - <<'EOF'
  import json, sys
  sys.path.insert(0, "src")
  from case_id import resolve_case_id
  manifest = json.load(open("<manifest.json>"))
  for row in manifest[:10]:
      stem = row.get("filename","").replace(".pdf","").replace(".mp4","")
      result = resolve_case_id(stem)
      print(f"{stem!r:60s} -> {result}")
  EOF
  ```
  Pass: all 10 return non-MISC. Fail: any MISC result → new pattern needed before T0.

- [ ] **5. Schema constraint dry-run** — Does worst-case worker output validate against the Pydantic schema?
  Pick the most complex file (most pages, longest expected text blocks) and run a manual schema probe. Confirm max quote length and citation fields pass validation.

- [ ] **6. Bare-binary subprocess check** — Every `subprocess.run([...])` in driver code uses absolute paths.
  ```bash
  grep -rn "subprocess.run\|subprocess.Popen" src/ \
    | grep -E '"uv"|"claude"|"ffmpeg"|"whisper"|"python"' \
    | grep -v '"/'
  ```
  Pass: 0 results. Fail: any bare binary → fix before T0.

- [ ] **7. Atomic claim check** — If MAX_PARALLEL > 1, is the claim step a single atomic statement?
  ```bash
  grep -n "pick_next_row\|claim_next\|UPDATE.*RETURNING" src/queue.py
  ```
  Verify the implementation uses `UPDATE ... WHERE ... = (SELECT ... LIMIT 1) RETURNING *`, not a separate SELECT then UPDATE. If MAX_PARALLEL == 1, mark N/A.

- [ ] **8. EXIT code semantics** — Does the driver distinguish race-lose from real failure?
  ```bash
  grep -n "EXIT_\|sys.exit\|raise SystemExit" src/*.py
  ```
  Confirm race-lose code is distinct from `EXIT_GENERIC_ERROR`. No shared codes between the two conditions.

- [ ] **9. Test hermeticity** — No production paths in tests.
  ```bash
  grep -rn "~/data\|~/studio\|DB_ROOT" tests/
  ```
  Pass: 0 results, or all results are inside a `tmp_path` / patched fixture context. Fail: any bare production path literal in test code → HALT, fix fixtures first.

- [ ] **10. 3-file sequential smoke** — Before parallel ingest, run 3 files SEQUENTIALLY (one per kind) and verify all audit gates pass on each.
  ```bash
  python -m src.supervisor --one-shot --csv-row <pdf_row_id>
  python -m src.supervisor --one-shot --csv-row <video_row_id>
  python -m src.supervisor --one-shot --csv-row <audio_row_id>
  ```
  Verify all audit gates pass on each file. Only after all 3 pass do you flip to parallel ingest.

**If any item above is unchecked or failed: you are NOT launch-and-go. You are launch-and-debug.**

---

## Phase 2 — Stand Up Bug and Lessons Discipline

Before writing the first tick of production ingest:

1. **Stamp the per-project bug log** if it does not already exist:
   ```bash
   cp ~/projects/_template/_BUGS.README.md \
      ~/projects/<project-name>/_BUGS.README.md
   # Edit: replace <PROJECT_NAME> and YYYY-MM-DD at the top
   ```

2. **Open the bug log in a persistent note.** Every bug found during this session gets an entry BEFORE you write fix code. The end-of-session "I'll log it later" pattern does not work. It never happens later.

3. **Open lessons_learned.md** at `~/.claude/memory-ledger/lessons_learned.md`. When a bug reveals an architectural gap — not a one-off typo, but a pattern that will recur in the next project — it gets an entry there too.

4. **Record the pre-flight log outcome** in the `_BUGS.README.md` under a "Pre-flight log — <date>" section: which items passed, which required fixes before T0, what fixes were applied.

---

## Phase 3 — Execute via subagent-driven-development

All implementation work runs through `superpowers:subagent-driven-development`. Never batch reviews. Never skip the fix loop.

**Pattern for each task:**

```
Task: <atomic, named unit from the spec's task decomposition>
Actor: subagent (fresh per task — never reuse across tasks)
Review: spec-reviewer + code-quality-reviewer run after each task closes
Fix loop: if review returns issues, fix loop runs before declaring task done
```

**TaskCreate discipline:**
- One task per atomic deliverable
- Each task includes: context (project path, spec section, relevant schema), input (what currently exists), output (what must be true when done), acceptance (how to verify it)
- Review must pass before the next task starts

**If a bug surfaces during task execution:**
1. STOP the current task
2. Log the bug in `_BUGS.README.md` (symptom, root cause estimate, reproducer)
3. Create a fix task
4. Complete the fix task with its own review loop
5. Only then resume the original task

**Corpus-specific sequencing:**
- The 3 smoke files from Phase 1 item 10 established per-kind correctness
- Parallel ingest starts only after those pass
- Monitor the first 10–15 parallel ticks before declaring ingest stable

---

## Phase 4 — (Optional) Hand off to /supervisor for overnight autonomous mode

If the ingest is large (50+ files, multi-hour runtime) and you have confirmed stable operation for the first 10–15 ticks:

1. Confirm the supervisor has a Telegram notification hook wired and tested
2. Confirm the bug log is up to date
3. Confirm disk space headroom:
   ```bash
   df -h ~/data
   ```
4. Hand off:
   ```
   /supervisor <project-name> --overnight
   ```
5. Write a progress note to `docs/` before closing the session:
   - What was completed in Phase 3
   - What the supervisor will continue
   - Any known fragile spots to watch
   - Telegram ping target for completion

If stability is not confirmed after the first 10–15 ticks, do NOT hand off to overnight. Stay in Phase 3.

---

## Phase 5 — Hive Registration on Ship

When the ingest is complete and the project is ready to ship, run the 4-lane Hive registration per `~/projects/_template/REGISTRATION.README.md`.

For a pipeline project (has running subprocesses / cron / supervisor):

**Lane 2 — Project registration (minimum):**
1. Confirm project folder is under `~/projects/<project-name>/` with the full 5-subdir scaffold
2. Write the memory file: `~/.claude/projects/-home-system/memory/project_<name>.md`
3. Add the MEMORY.md index entry (one line, under 150 chars)
4. Register in MCP knowledge graph: entity + relations
5. Verify: memory file present in `~/.claude/memory-ledger/` within 5 min

**If the pipeline runs as a persistent container (has a port, emits OTel):** upgrade to Lane 1 via `STAMPING.md`.

**Acceptance gate:** per the REGISTRATION.README.md gate table — the artifact is not registered until every lane-specific check returns true.

---

## Refusal Triggers — STOP if you see yourself doing these

- ❌ Proceeding past a failed pre-flight item because "it's probably fine"
- ❌ Skipping the smoke test (item 10) because "we tested the individual components already"
- ❌ Writing fix code before logging the bug in `_BUGS.README.md`
- ❌ Handing off to overnight `/supervisor` before the first 10–15 ticks have run stably
- ❌ Running tests that write to `~/data` or `~/studio` without `tmp_path` isolation
- ❌ Editing a locked worker prompt without explicit Will approval
- ❌ Logging a bug in the per-project log but NOT in lessons_learned.md when the bug reveals a reusable architectural pattern
- ❌ Using bare binary names (`uv`, `claude`, `ffmpeg`) in subprocess calls
- ❌ Claiming "launch-and-go ready" without all 10 pre-flight items checked and passing

If any of these happen: halt, tell Will what you almost did, fix it.

---

## Memory write on completion

When the project ships, append to `~/.claude/memory-ledger/lessons_learned.md`:
- Which pre-flight items caught real bugs this run
- What pre-flight items should be added for the next project of this type
- What architectural gaps were found that were not in the checklist yet
- One-line rule going forward

Then update MEMORY.md if a new permanent lesson was captured.

---

## Reference paths

| What | Path |
|---|---|
| Pre-flight canonical (expanded, with commands) | `~/projects/_template/PREFLIGHT.README.md` |
| Bug log template | `~/projects/_template/_BUGS.README.md` |
| Hive registration recipe (4 lanes) | `~/projects/_template/REGISTRATION.README.md` |
| 3-stage chain visual | `~/projects/_template/architecture/launch-flow.html` |
| Spec-coder flow command | `~/.claude/commands/spec-code.md` |
| Lessons-learned ledger | `~/.claude/memory-ledger/lessons_learned.md` |
| Launch-and-go methodology memory | `~/.claude/projects/-home-system/memory/feedback_launch_and_go_methodology.md` |
| Reference build (niche-topic R2) | `~/projects/niche-topic-release-ingest/` |
| Reference bug log (niche-topic R2) | `~/data/rag_docs/research/niche-topic/_database/war-gov/niche-topic/_BUGS.README.md` |

---

**Bottom line:** pre-flight costs 10 minutes. A 2-day debug cycle costs 2 days. The choice is not between fast and slow — it is between launch-and-go and launch-and-debug. Run the checklist.
