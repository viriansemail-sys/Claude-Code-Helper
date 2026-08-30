#!/usr/bin/env bash
# Hook 1: PreToolUse on Agent dispatch
# PURPOSE: Block any Agent dispatch that lacks an INTEGRATION_ACCEPTANCE clause.
# Research/meta/audit agents are exempted via META:/AUDIT:/RESEARCH: tag in first 200 chars.
# Fails OPEN if jq is missing (don't lock out supervisor entirely).

set -euo pipefail

INPUT=$(cat)

# Fail open if jq not available
if ! command -v jq &>/dev/null; then
  exit 0
fi

# Only act on Agent tool calls
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // ""')
if [[ "$TOOL_NAME" != "Agent" ]]; then
  exit 0
fi

PROMPT=$(echo "$INPUT" | jq -r '.tool_input.prompt // .tool_input.description // ""')

# Check for research/meta/audit exemption in first 200 chars
FIRST200="${PROMPT:0:200}"
if echo "$FIRST200" | grep -qiE '^(META:|AUDIT:|RESEARCH:)'; then
  exit 0
fi

# Check for INTEGRATION_ACCEPTANCE clause anywhere in prompt
if echo "$PROMPT" | grep -qiE 'INTEGRATION_ACCEPTANCE|integration acceptance|live system|user flow'; then
  exit 0
fi

# Block — no integration acceptance clause found
cat <<'EOF'
{"decision":"block","reason":"Supervisor discipline: every Agent dispatch needs an INTEGRATION_ACCEPTANCE clause specifying the user flow that proves the change works against the live system. Add INTEGRATION_ACCEPTANCE: <description of what you will test against the live system> to the dispatch prompt. Exception: prefix prompt with META:, AUDIT:, or RESEARCH: for research/meta agents."}
EOF
