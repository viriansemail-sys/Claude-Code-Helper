#!/usr/bin/env bash
# Hook 4: PostToolUse on Agent completion
# PURPOSE: Extract claimed commit SHA from agent report, cross-reference against
# target node git log, and append JSONL event to night_shift_log.jsonl.
# This codifies the parallel-commit-race instinct automatically.
# Fails OPEN entirely — never blocks, only appends a log entry.

set -uo pipefail

# DISABLED 2026-06-16 (Will): fired false "SHA CROSSREF WARNING" on every Agent
# completion by misreading agent task-dir UUIDs as commit SHAs. Noise, not signal.
exit 0

INPUT=$(cat)
LOG_FILE="~/data/logs/night_shift_log.jsonl"
SSH_TARGET="user@<lan-ip>"  # Default: the system node
TIMESTAMP=$(date -u '+%Y-%m-%dT%H:%M:%SZ')

# Fail open if jq missing
if ! command -v jq &>/dev/null; then
  exit 0
fi

TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // ""')
if [[ "$TOOL_NAME" != "Agent" ]]; then
  exit 0
fi

# Extract agent output/result
AGENT_OUTPUT=$(echo "$INPUT" | jq -r '.tool_response.result // .tool_response.output // .tool_response // ""' 2>/dev/null || true)
if [[ -z "$AGENT_OUTPUT" ]]; then
  exit 0
fi

# Extract SHA patterns from agent output (7-40 hex chars, often prefixed with "commit ", "SHA: ", etc.)
CLAIMED_SHA=$(echo "$AGENT_OUTPUT" | grep -oiE '(commit\s+|sha:?\s*|merged\s+)[0-9a-f]{7,40}|^[0-9a-f]{40}$' | grep -oiE '[0-9a-f]{7,40}' | head -1 || true)

# If no explicit SHA, try to find any standalone hex string that looks like a git sha
if [[ -z "$CLAIMED_SHA" ]]; then
  CLAIMED_SHA=$(echo "$AGENT_OUTPUT" | grep -oiE '\b[0-9a-f]{40}\b|\b[0-9a-f]{12}\b|\b[0-9a-f]{7}\b' | head -1 || true)
fi

# Build log entry
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // "unknown"')

if [[ -z "$CLAIMED_SHA" ]]; then
  # No SHA found — log that the agent reported without a verifiable commit reference
  ENTRY=$(jq -n \
    --arg ts "$TIMESTAMP" \
    --arg sid "$SESSION_ID" \
    --arg output "${AGENT_OUTPUT:0:500}" \
    '{timestamp: $ts, event: "agent_completion_no_sha", session_id: $sid, claimed_sha: null, crossref_result: "no_sha_in_report", agent_output_excerpt: $output}')
  echo "$ENTRY" >> "$LOG_FILE" 2>/dev/null || true
  exit 0
fi

# Cross-reference SHA against target node git log
REMOTE_LOG=$(ssh -o ConnectTimeout=5 -o BatchMode=yes "$SSH_TARGET" "git -C /opt/system/router log --oneline -10 2>/dev/null || git -C ~ log --oneline -10 2>/dev/null || echo 'NO_REPO'" 2>/dev/null || echo "SSH_FAILED")

SHA_VERIFIED="false"
if echo "$REMOTE_LOG" | grep -qi "$CLAIMED_SHA"; then
  SHA_VERIFIED="true"
fi

ENTRY=$(jq -n \
  --arg ts "$TIMESTAMP" \
  --arg sid "$SESSION_ID" \
  --arg sha "$CLAIMED_SHA" \
  --arg verified "$SHA_VERIFIED" \
  --arg remote_log "${REMOTE_LOG:0:500}" \
  --arg target "$SSH_TARGET" \
  '{timestamp: $ts, event: "agent_sha_crossref", session_id: $sid, claimed_sha: $sha, sha_verified: $verified, target_node: $target, remote_log_excerpt: $remote_log}')

echo "$ENTRY" >> "$LOG_FILE" 2>/dev/null || true

# Inject result back into model context if SHA could not be verified
if [[ "$SHA_VERIFIED" != "true" ]]; then
  cat <<EOF
{"hookSpecificOutput":{"hookEventName":"PostToolUse","additionalContext":"SHA CROSSREF WARNING: Agent claimed commit SHA ${CLAIMED_SHA} but it was NOT found in the last 10 commits on ${SSH_TARGET}. Remote log: ${REMOTE_LOG:0:300}. Investigate before proceeding — this may indicate a commit race or the agent reported a SHA from a different repo/branch."}}
EOF
fi

exit 0
