#!/bin/bash
# sweep-sessions-to-nas.sh — cron-driven safety net for abandoned sessions.
#
# Handles the "I closed the terminal" case where SessionEnd never fired:
#   1. Mirror any JSONL modified in the last 30 min (catches Stop-hook misses too)
#   2. Render .md for any JSONL on NAS whose source hasn't been touched in 10 min
#      AND that lacks a sibling .md yet
#
# Idempotent. Safe to run as often as you like.

set -u
ARCHIVE_ROOT="~/claude-archives/sessions"
PROJECTS_DIR="${HOME}/.claude/projects/-home-system"
LOG="${ARCHIVE_ROOT}/.sweep.log"

[ -d "$PROJECTS_DIR" ] || exit 0
mountpoint -q ~/archive 2>/dev/null || [ -d "$ARCHIVE_ROOT" ] || exit 0

DATE="$(date +%Y-%m-%d)"
DEST_DIR="${ARCHIVE_ROOT}/${DATE}"
mkdir -p "$DEST_DIR" 2>/dev/null || exit 0

mirrored=0
rendered=0

# (1) Mirror recently-active JSONLs (last 30 min)
while IFS= read -r SRC; do
  [ -z "$SRC" ] && continue
  SID="$(basename "$SRC" .jsonl)"
  # Place into the day-folder matching when the file was last modified, not "today"
  FILE_DAY=$(date -d "@$(stat -c %Y "$SRC")" +%Y-%m-%d 2>/dev/null || echo "$DATE")
  FILE_DEST_DIR="${ARCHIVE_ROOT}/${FILE_DAY}"
  mkdir -p "$FILE_DEST_DIR" 2>/dev/null
  DEST="${FILE_DEST_DIR}/${SID}.jsonl"
  if cp -u "$SRC" "$DEST" 2>/dev/null; then
    mirrored=$((mirrored+1))
  fi
done < <(find "$PROJECTS_DIR" -maxdepth 1 -name '*.jsonl' -mmin -30 2>/dev/null)

# (2) Render .md for any mirrored JSONL whose source went quiet >10 min ago
#     and that has no .md sibling yet
while IFS= read -r DEST; do
  [ -z "$DEST" ] && continue
  SID="$(basename "$DEST" .jsonl)"
  MD="${DEST%.jsonl}.md"
  [ -f "$MD" ] && continue
  SRC="${PROJECTS_DIR}/${SID}.jsonl"
  # If source still exists and was modified <10 min ago, session may still be live — skip
  if [ -f "$SRC" ] && [ $(($(date +%s) - $(stat -c %Y "$SRC"))) -lt 600 ]; then
    continue
  fi
  python3 - "$DEST" "$MD" <<'PY' 2>/dev/null && rendered=$((rendered+1))
import json, sys, pathlib
src, dst = sys.argv[1], sys.argv[2]
out = []
with open(src) as f:
    for raw in f:
        try:
            r = json.loads(raw)
        except Exception:
            continue
        role = r.get('type') or r.get('role') or ''
        msg = r.get('message') or {}
        content = msg.get('content') if isinstance(msg, dict) else None
        text = ''
        if isinstance(content, str):
            text = content
        elif isinstance(content, list):
            parts = []
            for c in content:
                if isinstance(c, dict):
                    if c.get('type') == 'text':
                        parts.append(c.get('text',''))
                    elif c.get('type') == 'tool_use':
                        parts.append(f"[tool: {c.get('name','?')}]")
                    elif c.get('type') == 'tool_result':
                        parts.append('[tool_result]')
            text = '\n'.join(p for p in parts if p)
        if not text:
            continue
        ts = r.get('timestamp','')
        out.append(f"## {role} {ts}\n\n{text}\n")
pathlib.Path(dst).write_text('\n'.join(out))
PY
done < <(find "$ARCHIVE_ROOT" -maxdepth 2 -name '*.jsonl' 2>/dev/null)

echo "[$(date -Iseconds)] sweep: mirrored=${mirrored} rendered=${rendered}" >> "$LOG" 2>/dev/null || true
exit 0
