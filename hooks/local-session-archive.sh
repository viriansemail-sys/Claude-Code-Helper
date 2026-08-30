#!/bin/bash
# local-session-archive.sh — word-for-word local archive of every Claude Code session.
#
# Claude Code already writes the verbatim transcript of every session as JSONL
# under ~/.claude/projects/<project-dir>/<session-uuid>.jsonl — but it DELETES
# them after 30 days by default. This script copies them to a safe local folder
# so nothing is ever lost, organized by day.
#
#   ~/claude-archive/sessions/YYYY-MM-DD/<session-uuid>.jsonl
#
# ALSO extend retention in ~/.claude/settings.json (belt + suspenders):
#   { "cleanupPeriodDays": 99999 }
#
# Run it every 5 minutes:
#   crontab -e   →   */5 * * * * $HOME/.claude/hooks/local-session-archive.sh
#   (Windows without WSL: run via Task Scheduler with Git-Bash, same interval.)
# Or wire it as a Stop/SessionEnd hook in settings.json — cron is the safety
# net for the "I closed the terminal" case where hooks never fire.
#
# Incremental (only files touched in the last 30 min), idempotent, fail-open.
# Run with --all to backfill every existing session once after install.

set -u
ARCHIVE_ROOT="${CLAUDE_ARCHIVE_ROOT:-$HOME/claude-archive/sessions}"
PROJECTS_ROOT="${HOME}/.claude/projects"
LOG="${ARCHIVE_ROOT}/.sweep.log"

[ -d "$PROJECTS_ROOT" ] || exit 0
mkdir -p "$ARCHIVE_ROOT" 2>/dev/null || exit 0

ALL=0
[ "${1:-}" = "--all" ] && ALL=1

if [ "$ALL" = "1" ]; then
  FIND_WINDOW=()
else
  FIND_WINDOW=(-mmin -30)
fi

mirrored=0
while IFS= read -r SRC; do
  [ -z "$SRC" ] && continue
  SID="$(basename "$SRC" .jsonl)"
  # File lands in the day-folder matching its last-modified date (GNU/BSD stat both tried)
  MTIME=$(stat -c %Y "$SRC" 2>/dev/null || stat -f %m "$SRC" 2>/dev/null || echo "")
  if [ -n "$MTIME" ]; then
    FILE_DAY=$(date -d "@$MTIME" +%Y-%m-%d 2>/dev/null || date -r "$MTIME" +%Y-%m-%d 2>/dev/null || date +%Y-%m-%d)
  else
    FILE_DAY=$(date +%Y-%m-%d)
  fi
  DEST_DIR="${ARCHIVE_ROOT}/${FILE_DAY}"
  mkdir -p "$DEST_DIR" 2>/dev/null
  DEST="${DEST_DIR}/${SID}.jsonl"
  # cp -u: only copy when source is newer — idempotent, cheap
  if cp -u "$SRC" "$DEST" 2>/dev/null; then
    mirrored=$((mirrored+1))
  fi
done < <(find "$PROJECTS_ROOT" -mindepth 2 -maxdepth 2 -name '*.jsonl' "${FIND_WINDOW[@]}" 2>/dev/null)

echo "$(date -Is) mirrored=${mirrored} all=${ALL}" >> "$LOG" 2>/dev/null
exit 0
