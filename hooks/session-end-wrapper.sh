#!/bin/bash
# Wrapper that finds the ECC hook script regardless of version
SCRIPT=$(find ~/.claude/plugins/cache/everything-claude-code -name "session-end.js" 2>/dev/null | head -1)
[ -n "$SCRIPT" ] && node "$SCRIPT" || exit 0
