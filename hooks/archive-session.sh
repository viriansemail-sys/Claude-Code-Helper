#!/bin/bash
# Archive hook — saves conversation summary on Stop and PreCompact
# Called by Claude Code hooks system

TRIGGER="${1:-stop}"
ARCHIVE_DIR="~/claude-archives/conversations"
DATE=$(date +%Y-%m-%d)
YEAR=$(date +%Y)
MONTH=$(date +%m)
TIMESTAMP=$(date -Iseconds)

# Create directory structure
mkdir -p "${ARCHIVE_DIR}/${YEAR}/${MONTH}"

# Log that archive was triggered (for debugging)
echo "[${TIMESTAMP}] Archive hook triggered: ${TRIGGER}" >> "${ARCHIVE_DIR}/archive.log"

# The actual archiving is done by the /archive skill invoked within Claude Code
# This hook just logs the trigger event — the skill handles content generation
# because only Claude Code has access to the conversation context

# For PreCompact, we note that context is about to be compressed
if [ "$TRIGGER" = "precompact" ]; then
    echo "[${TIMESTAMP}] PreCompact detected — conversation context about to be compressed" >> "${ARCHIVE_DIR}/archive.log"
fi

exit 0
