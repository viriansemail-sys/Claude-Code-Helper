#!/bin/bash
# Wrapper that finds the ECC evaluate-session hook regardless of version
SCRIPT=$(find ~/.claude/plugins/cache/everything-claude-code -name "evaluate-session.js" 2>/dev/null | head -1)
[ -n "$SCRIPT" ] && node "$SCRIPT" || exit 0
