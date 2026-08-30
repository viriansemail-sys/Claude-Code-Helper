#!/bin/bash
INPUT=$(cat)
TOOL="${CLAUDE_TOOL_USE_NAME:-unknown}"
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
SESSION="${CLAUDE_SESSION_ID:-unknown}"
FILEPATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // .tool_result.file_path // ""')
[ -z "$FILEPATH" ] && exit 0
LOG_LINE=$(jq -cn --arg ts "$TIMESTAMP" --arg session "$SESSION" --arg tool "$TOOL" --arg path "$FILEPATH" '{timestamp: $ts, session: $session, tool: $tool, path: $path}')
echo "$LOG_LINE" >> ~/data/logs/virian_file_writes.jsonl
exit 0
