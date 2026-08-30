#!/bin/bash
INPUT=$(cat)
CMD=$(echo "$INPUT" | jq -r '.tool_input.command // ""')
echo "$CMD" | grep -q '\bdocker\b' || exit 0
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
SESSION="${CLAUDE_SESSION_ID:-unknown}"
LOG_LINE=$(jq -cn --arg ts "$TIMESTAMP" --arg session "$SESSION" --arg cmd "$CMD" '{timestamp: $ts, session: $session, type: "docker", command: $cmd}')
echo "$LOG_LINE" >> ~/data/logs/virian_docker_audit.jsonl
exit 0
