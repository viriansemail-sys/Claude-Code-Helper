---
name: supervisor-bootstrap
description: Session-start orientation ritual for Night Shift Supervisor mode. Forces a structured self-check before any dispatch — reads active state, checks service liveness, tails the production log, reads open tasks, surfaces hard-won lessons, and outputs a mandatory state report. Prevents "wait, what's actually running?" drift. Invoked automatically as step 1 of every /supervisor call.
metadata:
  version: 1.0.0
  author: system-2026-04-26
  timelessness_score: 9
---

# Supervisor Bootstrap

**One call. 30 seconds. No more flying blind.**

This skill forces a structured orientation before the supervisor touches anything. It reads state, checks liveness, tails the log, loads open tasks, reads hard-won lessons, and produces a mandatory state report. If you skip this, you WILL drift.

## Quick Start

```
supervisor-bootstrap ~/projects/analysis
→ Runs full orientation, outputs state report

supervisor-bootstrap ~/projects/analysis --skip-liveness
→ Orientation without service liveness check (faster, less accurate)
```

## Triggers

- `Skill({skill: "supervisor-bootstrap", args: "<project_path>"})` — primary invocation
- Called automatically by `/supervisor <project>` as step 1
- `supervisor bootstrap` / `orient supervisor` — natural language triggers

## Arguments

| Arg | Required | Default | Description |
|-----|----------|---------|-------------|
| `project_path` | yes | — | Absolute path to project root |
| `--skip-liveness` | no | false | Skip service-liveness skill call (use if services are known-good or node is offline) |
| `--session-id` | no | auto-detect | Override session ID for archive entry |

---

## Execution Steps (in order — do NOT skip steps)

### Step 1 — Resolve project name

Extract `project_name` from the last path component of `project_path`.

```python
project_name = project_path.rstrip("/").split("/")[-1]
```

### Step 2 — Load active state

Look for state file in this priority order:

1. `<project_path>/memory/night_shift_state.md` — project-local state (preferred)
2. `~/.claude/projects/-home-system/memory/active_night_shift_state.md` — global fallback

Read the file. Extract:
- `current_wave` — look for `current_wave:` field or `## Wave N` heading
- `status` — look for `status:` field or overall status marker (RUNNING / COMPLETE / PARKED / BLOCKED)
- `last_event` — use the most recent bullet or log entry in the state file
- If NEITHER file exists: state = `DARK — no state file found at either location`

### Step 3 — Service liveness check

Check if `~/.claude/skills/service-liveness/SKILL.md` exists.

**If service-liveness skill is installed AND `--skip-liveness` is NOT set:**

Invoke:
```
Skill({skill: "service-liveness", args: "<project_path>"})
```

Parse the result for:
- Overall verdict: `PASS` / `FAIL` / `BLOCKED`
- Count of LIVE vs DEAD services
- Any DEAD service names

Summarize as: `N/M services live` or `PASS` or `FAIL (dead: <names>)`

**If service-liveness skill is NOT installed (fallback):**

Run inline check:
```bash
# Check if project has a docker-compose
if [ -f "<project_path>/deploy/docker-compose.yml" ]; then
  cd <project_path>/deploy && docker compose ps --format "table {{.Service}}\t{{.State}}\t{{.Status}}" 2>/dev/null \
  || ssh user@<lan-ip> "cd <project_path>/deploy && docker compose ps --format 'table {{.Service}}\t{{.State}}\t{{.Status}}' 2>/dev/null"
fi
```

If docker-compose not found, report: `service-liveness skill not installed; no docker-compose found — manual check required`

### Step 4 — Tail production log

Look for the production log in this priority order:
1. `<project_path>/data/night_shift_log.jsonl`
2. `<project_path>/data/*.jsonl` (newest by mtime if multiple)

Read the last 20 entries. Extract from the most recent entry:
- `ts` field → last action timestamp
- `event` field → last action description
- Any `status` field → last status

If no log found: `no production log found at <project_path>/data/`

Also scan all 20 entries for any `"dispatched"` or `"dispatch"` events without a corresponding `"complete"` or `"DONE"` event for the same task. These are in-flight agents.

### Step 5 — Read TaskList

Look for a task tracking file in this priority order:
1. Claude Code's active TodoList (the built-in task system — if a todo list is active in the current session, read it)
2. `<project_path>/memory/tasks.md`
3. `<project_path>/data/morning_brief_priorities.md` — parse for open items (lines starting with `- **`, `- CRIT`, `- HIGH`, `- MED` that are NOT marked `(FIXED)` or `(DONE)`)
4. `<project_path>/README.md` — look for `## TODO` or `## Open Items` section

Count:
- `pending_count` — tasks with status TODO / PENDING / open
- `in_progress_count` — tasks explicitly marked IN PROGRESS / DISPATCHED / RUNNING
- `summary` — first 3-5 task titles (truncate each at 80 chars)

If nothing found: `no task list found — check README.md or morning_brief_priorities.md`

### Step 6 — Read hard-won lessons

Read `~/.claude/commands/supervisor.md` — specifically the `### Hard-won lessons` section.

Do NOT reproduce all lessons in the output. Instead:
- Count how many lessons exist
- Pick the 2 most relevant to current project state (e.g., if services are DEAD → pick the lesson about verifying claims; if agents are in-flight → pick the lesson about cross-referencing SHAs)
- Store for inline reference in the state report

### Step 7 — Detect session ID

Look for the current session ID:
```bash
ls -t /tmp/claude-1000/-home-system/ 2>/dev/null | head -1
```

Use that as `session_id`. If not found, use `unknown-$(date +%Y%m%dT%H%M%SZ)`.

### Step 8 — Output state report (MANDATORY FORMAT — do not deviate)

Output this exact block. Every field MUST be populated. Never write "unknown" without explaining why.

```
## SUPERVISOR BOOTSTRAP — <project_name>

**System state:** [running / partially running / dark]
**Last action (per log):** <event from most recent log entry> (<ts>)
**Pending tasks:** <count + 1-line summary of top tasks>
**In-flight agents:** <list agent IDs / events from log if any, else "none detected">
**Open critical issues:** <CRIT/HIGH from morning_brief_priorities.md or equivalent, else "none found">

**Active lessons applied:**
- <lesson 1 (truncated to 1 line)>
- <lesson 2 (truncated to 1 line)>

**Service liveness:** <verdict — N/M services live, or PASS/FAIL/BLOCKED, or inline check result>

**Next action I will take:** <stated next move — specific, not vague>
```

**System state logic:**
- `running` — services PASS liveness + log has events in last 2 hours + active state file found
- `partially running` — some services down OR state file is stale (> 2 hours) OR log has in-flight events without completion
- `dark` — no state file, no log, services all down, or can't reach node

### Step 9 — Write session archive entry

Determine today's date: `$(date +%Y%m%d)`

Write a new entry to `<project_path>/data/session_archive_<date>.md` (append if file exists, create with header if not):

Header (create only if file is new):
```markdown
# Session Archive — <project_name>
_Auto-generated by supervisor-bootstrap skill_

```

Entry to append:
```markdown
---
## Supervisor Session Started — <ISO timestamp>

- **Session ID:** <session_id>
- **Project:** <project_name>
- **Bootstrap result:** <system_state>
- **Service liveness:** <verdict>
- **Last log event:** <last_event>
- **Open tasks at start:** <pending_count> pending, <in_progress_count> in-progress
- **Next action:** <stated next move>

```

---

## State Report — Field Definitions

| Field | Where it comes from | Never blank because |
|-------|---------------------|---------------------|
| System state | Derived from liveness + log recency + state file | Use `dark` if all checks fail |
| Last action | Most recent `event` in JSONL log | Use `no log found` if missing |
| Pending tasks | TaskList or brief_priorities | Use `no task list found` if missing |
| In-flight agents | JSONL log scan for unmatched dispatches | Use `none detected` if log is clean |
| Open critical issues | morning_brief_priorities.md CRIT/HIGH lines | Use `none found in <file>` if file clean |
| Next action | Supervisor's own judgment based on state | NEVER leave blank — if stuck, say "investigate <x>" |

---

## Anti-Patterns

| Avoid | Why | Instead |
|-------|-----|---------|
| Skipping bootstrap to "save time" | Saves 30s, wastes 30 minutes diagnosing stale state | Always run it |
| Leaving any field blank | Signals you didn't actually check | Use explicit "not found" values |
| Running liveness on wrong node | Shows green when services are on a different host | Check `docs/expected_services.yaml` for `node:` field |
| Writing "unknown" for system state | It's a cop-out | Derive from available signals — even partial data yields `partially running` |
| Ignoring in-flight agents | Leads to duplicate dispatches | Always scan JSONL for unmatched dispatch events |

---

## Integration with /supervisor

The `/supervisor` command MUST call this skill as its FIRST action, before reading the project README or planning waves. The state report produced by this skill IS the project context for the session — everything else builds on it.

If bootstrap reports `dark` (no state, no log, services down), the supervisor must reconcile the state before proceeding:
1. Check if project was manually modified
2. Check if a prior session's archive file (`data/session_archive_*.md`) explains the gap
3. Alert Will before dispatching any waves

---

## Timelessness Score: 9/10

The problem (supervisor drift from stale context) is permanent. Reading a state file + tailing a log + checking liveness are stable primitives. The output format can evolve but the shape is fixed. Only thing that could make this obsolete: a real-time supervisor dashboard with live state feeds — which would just make this skill's job easier, not unnecessary.
