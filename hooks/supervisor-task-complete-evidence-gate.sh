#!/usr/bin/env bash
# Hook 2: PreToolUse on TaskUpdate to status=completed
# PURPOSE: Block marking a task complete without recent evidence in the production log.
# Evidence = SHA / passing test ID / curl 200 / artifact path in night_shift_log.jsonl within last 30 min.
# Fails OPEN if log doesn't exist yet or jq missing.

set -euo pipefail

INPUT=$(cat)

# Fail open if jq missing
if ! command -v jq &>/dev/null; then
  exit 0
fi

TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // ""')
if [[ "$TOOL_NAME" != "TaskUpdate" && "$TOOL_NAME" != "Task" ]]; then
  exit 0
fi

STATUS=$(echo "$INPUT" | jq -r '.tool_input.status // ""')
if [[ "$STATUS" != "completed" ]]; then
  exit 0
fi

LOG_FILE="~/data/logs/night_shift_log.jsonl"

# Fail open if log doesn't exist
if [[ ! -f "$LOG_FILE" ]]; then
  exit 0
fi

# Look for evidence in last 30 minutes
CUTOFF=$(date -d '30 minutes ago' '+%s' 2>/dev/null || date -v-30M '+%s' 2>/dev/null || echo 0)
FOUND=0

while IFS= read -r line; do
  # Parse timestamp from JSONL entry
  TS=$(echo "$line" | jq -r '.timestamp // .ts // .time // ""' 2>/dev/null || true)
  if [[ -z "$TS" ]]; then continue; fi

  # Convert to epoch
  EPOCH=$(date -d "$TS" '+%s' 2>/dev/null || date -j -f '%Y-%m-%dT%H:%M:%S' "${TS%%.*}" '+%s' 2>/dev/null || echo 0)
  if [[ "$EPOCH" -lt "$CUTOFF" ]]; then continue; fi

  # Check for evidence patterns
  if echo "$line" | grep -qiE '[0-9a-f]{7,40}|PASS|curl.*200|artifact|\.jsonl|\.pt|\.safetensors|test.*pass|passed'; then
    FOUND=1
    break
  fi
done < "$LOG_FILE"

if [[ "$FOUND" -eq 1 ]]; then
  exit 0
fi

cat <<'EOF'
{"decision":"block","reason":"Supervisor discipline: cannot mark task complete without recent evidence in production log. Post a log entry to ~/data/logs/night_shift_log.jsonl with a SHA, passing test ID, curl 200 response, or artifact path first — then retry marking complete."}
EOF
