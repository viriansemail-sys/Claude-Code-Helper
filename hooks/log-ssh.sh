#!/bin/bash
INPUT=$(cat)
CMD=$(echo "$INPUT" | jq -r '.tool_input.command // ""')
echo "$CMD" | grep -q '\bssh\b' || exit 0
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
SESSION="${CLAUDE_SESSION_ID:-unknown}"
LOG_LINE=$(jq -cn --arg ts "$TIMESTAMP" --arg session "$SESSION" --arg cmd "$CMD" '{timestamp: $ts, session: $session, type: "ssh", command: $cmd}')
echo "$LOG_LINE" >> ~/data/logs/virian_ssh_audit.jsonl
exit 0
