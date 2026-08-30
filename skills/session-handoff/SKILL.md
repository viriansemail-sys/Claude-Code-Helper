---
name: session-handoff
description: End-of-session compact ritual. Writes a tight structured progress note (active project, last decision, next action, blockers, open questions, resume command) to disk so the next session — possibly a different model or context window — can resume cold without panic. Auto-suggest when current turn ≥ 100, or when Will says "wrap up", "session handoff", "end of day", "compact this", or appears to be ending. NOT a forensic record (use /archive for texture) — this is the 60-second resume artifact. Part of Project the assistant Renew Wave 0 (item D13). Foundation for ADHD-Help sub-project Block A item 2.
---

# /session-handoff — end-of-session compact ritual

## When to invoke

- Will says "wrap up", "session handoff", "end of day", "compact this", "park it"
- Auto-suggest when `turn-counter` ≥ 100 (deep context, close-to-compaction risk)
- Before a long Will-away (>2h) where the session might be auto-compacted
- After a wave/block boundary in a multi-wave build

**NOT for:**
- Forensic texture / "what was actually said" — use `/archive` (it captures the back-and-forth)
- Project closeout / verify deliverables — use `/closeout`
- Shipping a single completion to portfolio — use `/log-completion`
- Mid-session context recovery — use `/where-were-we` (D11)

## What it produces

ONE small markdown file at:

```
~/projects/<active-project>/handoffs/<YYYY-MM-DD>_<HH-MM>_handoff.README.md
```

If `<active-project>` can't be determined cleanly, write to `~/.claude/handoffs/<YYYY-MM-DD>_<HH-MM>_handoff.README.md` and surface that to the user so he can move it.

The file's purpose: a future cold session reads ONLY this file (plus the linked binding spec) and is fully oriented in <60 seconds.

## Hard rules

- **Tight.** Target ~30–60 lines total. If it's longer than `/archive` would be, you're doing it wrong.
- **Schema-strict.** Same fields every time — future-the assistant depends on shape.
- **Anti-drift SID.** Same lesson as D11/D12 — ground-truth the SID against `~/claude-archives/sessions/<today>/`, never from conversation context.
- **No "great session" tone.** Forensic terseness. Resume signal, not retrospective.
- **Surface OPEN questions explicitly** — these are the things the next session must NOT bypass.

## Required schema

```markdown
---
date: YYYY-MM-DD
time: HH:MM <TZ>
node: <hostname>
session_id: <UUID — ground-truthed from ~/claude-archives/sessions/>
project: <slug>
wave: <n or n/a>
progress: <X/Y items completed in current wave>
---

# Session handoff — <project> <wave> @ <date> <time>

## Active project
<one line: project path + binding spec path>

## Progress at handoff
- ✅ Completed (this session): #N <subject> ... (list)
- 🔄 In-flight when paused: #N <subject> — <state: e.g. "code written, verify pending">
- ⏭ Next concrete action: #N <subject> + file path or command
- 🚧 Blocked: #N <subject> — <reason + who/what unblocks>

## Last decision committed
<one paragraph: what was decided, evidence/source>

## Open questions Will must answer before continuing
1. <question> — default recommendation if any
2. <question>

## Hard rules active for this work
<bullet list — copy from binding spec OR new rules added this session>

## Resume command (one line, copy-pasteable)
```
Read <binding-spec-path> and <this-handoff-path>. Pick up at item #N — <next concrete action>. Anti-drift mode active.
```

## Receipts
- Session archive (raw jsonl): `~/claude-archives/sessions/YYYY-MM-DD/<sid>.jsonl`
- Session archive (rendered md): same with `.md`
- Forensic archive (if `/archive` ran): `~/claude-archives/conversations/YYYY/MM/<date>_<slug>.README.md`
- Binding spec: `<path>`
- Memory file: `<path if updated this session>`
```

## Procedure

### Step 1 — anchor the SID (anti-drift)

```bash
SID=$(ls -lt ~/claude-archives/sessions/$(date +%Y-%m-%d)/*.jsonl 2>/dev/null | head -1 | awk '{print $NF}' | xargs -r basename | sed 's/\.jsonl$//')
test -n "$SID" || echo "WARN: SID lookup failed — fall back to /tmp/claude-1000/-home-system/ listing"
```

### Step 2 — determine active project

Check in order:
1. Most-recently-edited file in `~/projects/*/` (mtime in last 4h) → infer project slug from path
2. Most recent `[in_progress]` task's description for project references
3. If both ambiguous → AskUserQuestion: "Active project for handoff?"

### Step 3 — pull TaskList state

Use `TaskList` tool. Extract:
- All `completed` items (label them "this session" — derive from session start time vs task completion timestamps if available)
- The single `in_progress` (if any)
- First `pending` item (= next concrete action)
- Any task with `blockedBy` set (= blocked)

### Step 4 — extract last locked decision

Source of truth, in order:
1. Last `decisions/` ADR added to project (mtime in this session)
2. Most recent MEMORY.md edit (one-line index entry summarizes)
3. Last "Decision LOCKED" from any `/archive` doc written this session

### Step 5 — surface open questions

Pull from:
- Binding spec's "Open questions" section
- Any unresolved `[VERIFY]` flags introduced this session
- Anything the user said "let's decide later" / "for another day" about

### Step 6 — write the handoff file

Path resolution:
- If active project = X → `~/projects/X/handoffs/<date>_<time>_handoff.README.md`
- Create dir if not present
- Filename uses `_handoff.README.md` suffix to satisfy the global no-non-README hook

### Step 7 — emit to screen + Telegram (optional)

Print the file PATH (not its full contents) to chat:

```
HANDOFF SAVED:
  → ~/projects/<slug>/handoffs/<date>_<time>_handoff.README.md
  Resume command:
    <one-line resume command from the file>
```

If Telegram MCP available and Will requested it (or it's auto-handoff at turn 100+ on an autonomous shift), POST the same to the configured chat — never the bot ID/chat ID in the chat output (OPSEC).

## Examples

**Good (the entire file body for a sample handoff):**
```
# Session handoff — project-assistant-renew Wave 0 @ 2026-06-08 10:15

## Active project
~/projects/project-assistant-renew/ — spec: docs/specs/2026-06-06_wave-0/README.md

## Progress at handoff
- ✅ Completed (this session): A1, A2, A3, A4, B5, C6, C7, C8, C9, C10, D11, D12, D13 (this)
- 🔄 In-flight when paused: none — at a clean phase boundary
- ⏭ Next concrete action: D14 rabbit-hole guard hook (~/.claude/hooks/rabbit-hole-guard.sh)
- 🚧 Blocked: none

## Last decision committed
D13 /session-handoff skill shipped per Wave 0 spec. Tight schema, anti-drift SID, project-routed handoff path.

## Open questions Will must answer before continuing
1. OQ#3 — /claude-this-week delivery channel? Default: Telegram + NAS markdown
2. Promote WARN hooks → BLOCK on 2026-06-15 after telemetry review?

## Hard rules active for this work
- Anti-drift mode active
- Isolation-test hooks before settings.json
- WARN-only hook mode for 1 week

## Resume command
```
Read ~/projects/project-assistant-renew/docs/specs/2026-06-06_wave-0/README.md and ~/projects/project-assistant-renew/handoffs/2026-06-08_10-15_handoff.README.md. Pick up at D14 rabbit-hole guard hook. Anti-drift mode active.
```

## Receipts
- ~/claude-archives/sessions/2026-06-08/<sid>.jsonl
- ~/claude-archives/conversations/2026/06/2026-06-08_claudia-renew-wave-0-block-c-checkpoint.README.md
- ~/projects/project-assistant-renew/docs/specs/2026-06-06_wave-0/README.md
```

**Bad:**
- ❌ "Great session, we got a lot done!" (no resume signal)
- ❌ 300 lines of back-and-forth recap (that's /archive)
- ❌ Omits Open Questions (next session will guess and drift)
- ❌ Resume command that just says "continue" (must name the next item + path)
- ❌ Inferred project when ambiguous instead of asking

## Cross-references

- D11 `/where-were-we` — in-session counterpart (mid-session recovery, no file write)
- D12 `/morning-system` — start-of-day counterpart (this skill is the end-of-day bookend)
- `/archive` — forensic record companion (call BOTH for important sessions: archive for texture, handoff for resume)
- `/closeout` — project-end audit (when a WHOLE project is done, not just a session)
- `/log-completion` — portfolio ledger entry (when shipping a tangible asset)
- Memory file: `[[user_will_has_adhd]]` — the WHY this skill exists (ADHD context loss between sessions)
- Wave 0 spec: `~/projects/project-assistant-renew/docs/specs/2026-06-06_wave-0/README.md` item D13
- ADHD-Help sub-project Block A item 2 extends THIS skill with anti-shame language + Cortex deposit. Build this first; ADHD layer plugs in later.
