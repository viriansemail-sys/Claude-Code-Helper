---
name: where-were-we
description: 5-second context recovery skill for ADHD rabbit-hole exits. Reads the last ~20 turns of the active session jsonl, the current TaskList in_progress item, and the most recently edited memory file, then produces a 3-sentence "you were doing X, last decision was Y, next action is Z." Use when Will says "where were we", "what was I doing", "lost the thread", or after a tangent. Part of Project the assistant Renew Wave 0 (item D11).
---

# /where-were-we — 5-second context recovery

## When to invoke

Will says any of:
- "where were we"
- "what was I doing"
- "lost the thread"
- "remind me"
- after a tangent / interruption / topic shift
- after a long subagent fan-out where the parent thread got buried

## Hard rules

1. **Three sentences. Not four. Not bullets.** The skill exists to lower activation energy after a rabbit-hole — overlong output defeats the purpose.
2. **Quote the user's exact most recent ask** as part of sentence 1 — paraphrasing IS the drift this skill fights.
3. **Never invent a "next action"** that isn't visible in TaskList in_progress or the binding spec on disk. If nothing is in_progress, say so.
4. **Ground every sentence in evidence on disk** — session jsonl, TaskList, memory file, or named project doc.

## Procedure

### Step 1 — find this session's live transcript

```bash
ls -lt ~/claude-archives/sessions/$(date +%Y-%m-%d)/*.jsonl 2>/dev/null | head -3
```

The most-recently-mtimed jsonl is THIS session. Capture its path. **Do NOT trust a SID pasted in conversation context** — ground-truth against the directory listing (2026-06-08 lesson: `feedback_self_quoted_sid_drift`).

### Step 2 — pull the last ~20 turns

```bash
# Tail the rendered .md mirror if present (faster) — else the jsonl
SID_PATH=<from-step-1>
MD_PATH="${SID_PATH%.jsonl}.md"
if [[ -r "$MD_PATH" ]]; then
  tail -200 "$MD_PATH"
else
  tail -n 40 "$SID_PATH" | python3 -c '
import sys, json
for line in sys.stdin:
    try:
        row = json.loads(line)
    except Exception:
        continue
    msg = row.get("message") or {}
    role = msg.get("role") or row.get("type") or ""
    if role not in ("user","assistant"): continue
    content = msg.get("content") or []
    if isinstance(content, str):
        print(f"[{role}] {content[:300]}")
    else:
        for c in content:
            if isinstance(c, dict) and c.get("type") == "text":
                print(f"[{role}] {c.get(\"text\",\"\")[:300]}")
'
fi
```

### Step 3 — read the live TaskList

Invoke the `TaskList` tool. Identify:
- Single `in_progress` item (there should be at most one — that IS the answer to "what were you doing")
- Most recently `completed` item (last decision committed)
- First `pending` item after the in_progress (next concrete action)

### Step 4 — read the most recently edited memory file

```bash
ls -t ~/.claude/projects/-home-system/memory/*.md | head -3
```

Skim the top one for any rule/decision that calibrates the current task.

### Step 5 — emit the 3-sentence answer

Strict format:

```
WHERE WE WERE:
  1. You were <verbatim recent user ask or in_progress task subject>.
  2. Last decision: <most-recently-completed task OR locked decision from memory>.
  3. Next: <first pending item after in_progress, with file path or command>.
```

That's the entire output. No headers above it, no extra commentary below it.

## Examples

**Good (what to emit):**
```
WHERE WE WERE:
  1. You were building Wave 0 item D11 — the /where-were-we skill itself.
  2. Last decision: C10 context-refresh-tick.sh shipped WARN-mode and registered in UserPromptSubmit.
  3. Next: D12 /morning-system skill (~/.claude/skills/morning-system/SKILL.md).
```

**Bad (don't do this):**
- ❌ Bulleted exhaustive recap of last 20 turns
- ❌ "Looks like you were working on Project the assistant Renew Wave 0 which is a forever-running meta-project that..." (paraphrasing)
- ❌ "Next: probably the ADHD skills" (no verb, no path, hedging)
- ❌ Inventing a next action from memory rules when TaskList has nothing pending

## When NOT to invoke

- At session start with no prior context (use `/morning-system` instead — that's the daily ritual)
- When Will is mid-explanation (interrupting with a recap is drift, not recovery)
- For multi-session questions ("what did I do last week") — use `/sessions list` or the conversation archives at `~/claude-archives/conversations/INDEX.md` instead

## Cross-references

- D12 `/morning-system` — full daily ritual (this skill is the in-session subset)
- D13 `/session-handoff` — end-of-session compact ritual
- Anti-drift skill — uses a similar 5-step refresh ritual; this skill is the lightweight ADHD-tuned version
- Memory file: `[[user_will_has_adhd]]` — the WHY this skill exists
- Wave 0 spec: `~/projects/project-assistant-renew/docs/specs/2026-06-06_wave-0/README.md`
