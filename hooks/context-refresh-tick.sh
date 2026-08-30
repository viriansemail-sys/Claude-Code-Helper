#!/usr/bin/env bash
# UserPromptSubmit hook — Project the assistant Renew Wave 0 item C10.
# Every N turns (default 30), re-inject the 5 core CLAUDE.md hard rules so
# discipline survives deep context. Counter is per-session, stored under /tmp.
#
# [VERIFY] Claude Code has no native periodic hook event — UserPromptSubmit +
# counter file is the closest implementation. Side effect: counter resets if
# /tmp is cleared between sessions (fine — counter is per-session).
#
# Cooperates with the specialist-suggester (also UserPromptSubmit) — both can fire
# the same turn; both print independent hookSpecificOutput JSON, but only ONE wins
# (last one stdout). To be safe, this tick injects via stderr text (which is also
# surfaced) when it's *not* a refresh turn we skip; on refresh turns we emit JSON.

set -u

PERIOD="${CONTEXT_REFRESH_PERIOD:-30}"

input="$(cat)"

sid="$(printf '%s' "$input" | python3 -c '
import sys, json
try:
    print(json.load(sys.stdin).get("session_id",""))
except Exception:
    print("")
' 2>/dev/null)"

[[ -z "$sid" ]] && exit 0

STATE_DIR="/tmp/claude-1000/-home-system/${sid}"
mkdir -p "$STATE_DIR" 2>/dev/null || exit 0
COUNTER="$STATE_DIR/turn-counter"

# Read + increment + write atomically-enough for single-writer use.
n=0
[[ -r "$COUNTER" ]] && n=$(cat "$COUNTER" 2>/dev/null || echo 0)
n=$(( n + 1 ))
printf '%d\n' "$n" > "$COUNTER"

# Not a refresh turn? Exit silent.
(( n % PERIOD == 0 )) || exit 0

# Refresh turn: emit additionalContext with the 5 rules.
python3 - "$n" "$PERIOD" <<'PY'
import json, sys
n, period = sys.argv[1], sys.argv[2]
msg = f"""[context-refresh-tick] Turn {n} (every {period}). Re-anchor to the 5 CLAUDE.md hard rules:

  1. Pre-Flight 4-Question Template — before any 3+ step task, ask Scope/Success/Blast-radius/Deadline in one sentence each. Wait for answers.
  2. Specialist-Surface Habit — before dispatching a subagent, NAME 2-3 candidates with one-line rationale, then pick. Never general-purpose.
  3. Build-vs-Buy Precondition — before writing any new file, state in chat what was checked: installed skills, installed agents, existing hive projects, OSS via web.
  4. Task → Action Map — phrase-keyed lookup at line 339 of CLAUDE.md. Match the user's exact wording to specialist BEFORE deciding.
  5. Single-Recommendation rule (mid-execution) — lead with ONE concrete suggestion; option menus only in brainstorm mode.

Plus the verify-before-completion gate: NO completion claims without a fresh evidence command run THIS turn."""
print(json.dumps({
  "hookSpecificOutput": {
    "hookEventName": "UserPromptSubmit",
    "additionalContext": msg
  }
}))
PY
exit 0
