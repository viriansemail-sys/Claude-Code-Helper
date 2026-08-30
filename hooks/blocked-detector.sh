#!/usr/bin/env bash
# Stop hook — Project the assistant Renew Wave 0 item C7.
# Scans the assistant's final assistant message for blocker language.
# If detected AND no WebSearch/WebFetch in the last 10 tool calls → emit WARN.
# Mode: WARN-only for 1 week (Will, OQ#2, 2026-06-07). Promote to BLOCK after telemetry.
# Exit 0 always while in WARN mode.

set -u

input="$(cat)"

# Stop hook stdin shape: {"session_id":..., "transcript_path":..., "stop_hook_active":bool}
transcript="$(printf '%s' "$input" | python3 -c '
import sys, json
try:
    d = json.load(sys.stdin)
    print(d.get("transcript_path") or "")
except Exception:
    print("")
' 2>/dev/null)"

[[ -z "$transcript" || ! -r "$transcript" ]] && exit 0

# Pull last assistant message text + last 10 tool calls from transcript.
result="$(python3 - "$transcript" <<'PY' 2>/dev/null
import json, sys, re
path = sys.argv[1]
last_text = ""
tool_calls = []  # most recent last
with open(path) as f:
    for line in f:
        try:
            row = json.loads(line)
        except Exception:
            continue
        msg = row.get("message") or {}
        role = msg.get("role") or row.get("type") or ""
        # Assistant text blocks
        if role == "assistant":
            content = msg.get("content") or []
            if isinstance(content, list):
                txt = " ".join(c.get("text","") for c in content if isinstance(c,dict) and c.get("type")=="text")
                if txt.strip():
                    last_text = txt
                for c in content:
                    if isinstance(c, dict) and c.get("type") == "tool_use":
                        tool_calls.append(c.get("name",""))
recent = tool_calls[-10:]
blockers = re.compile(r"\b(blocked|can'?t (be )?done|no path|not (possible|supported|available)|doesn'?t (work|support)|isn'?t supported|impossible|won'?t work)\b", re.IGNORECASE)
m = blockers.search(last_text or "")
web_used = any(t in ("WebSearch","WebFetch") for t in recent)
if m and not web_used:
    print(json.dumps({"trigger": m.group(0), "recent_tools": recent}))
PY
)"

[[ -z "$result" ]] && exit 0

trigger="$(printf '%s' "$result" | python3 -c 'import sys,json; print(json.load(sys.stdin)["trigger"])')"

# Emit warning via stderr (harness surfaces this in the "Ran N stop hooks" UI panel).
# 2026-06-08 fix: previous version emitted {"hookSpecificOutput": {...}} JSON on stdout,
# which is the schema for UserPromptSubmit/SessionStart hooks — NOT Stop hooks.
# Stop hook output schema only accepts root-level decision/reason/continue/stopReason,
# so the harness rejected the payload with "(root): Invalid input" and printed an error
# every Stop where blocker-language + no-web triggered the hit. Routing to stderr keeps
# the WARN visible without violating the StopHookOutput JSON schema.
{
  printf '[blocked-detector WARN] Final response contains blocker language ("%s") ' "$trigger"
  printf 'but no WebSearch/WebFetch was used in the last 10 tool calls.\n'
  printf 'Per Will hard rule (2026-05-24): web-search the EXACT issue before declaring blocked.\n'
  printf 'WARN-only for 1 week; promotes to BLOCK after telemetry.\n'
} >&2

# Telemetry: append the hit so we can review after 1 week before flipping to BLOCK.
LOG="~/data/logs/blocked-detector-hits.jsonl"
mkdir -p "$(dirname "$LOG")" 2>/dev/null || true
ts="$(date -Iseconds)"
sid="$(printf '%s' "$input" | python3 -c 'import sys,json; print(json.load(sys.stdin).get("session_id",""))' 2>/dev/null || echo "")"
printf '{"ts":"%s","session_id":"%s","trigger":"%s"}\n' "$ts" "$sid" "$trigger" >> "$LOG" 2>/dev/null || true

exit 0
