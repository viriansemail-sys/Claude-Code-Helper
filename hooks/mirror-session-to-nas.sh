#!/bin/bash
# mirror-session-to-nas.sh — incrementally copy the active session JSONL transcript to NAS.
#
# Wired to Stop (every assistant turn) and SessionEnd (final flush + .md render).
# Idempotent: rsync only moves changed bytes; safe to fire every turn.
#
# Destination: ~/claude-archives/sessions/YYYY-MM-DD/<session-id>.jsonl
# Optional sibling: <session-id>.md (rendered on SessionEnd only)
#
# Failure-tolerant: if NAS is unmounted, exits 0 silently so the harness never blocks.

set -u

EVENT="${1:-stop}"
ARCHIVE_ROOT="~/claude-archives/sessions"
PROJECTS_DIR="${HOME}/.claude/projects/-home-system"
LOG="${ARCHIVE_ROOT}/.mirror.log"

# Drain stdin JSON payload — extract session_id if jq available
INPUT="$(cat)"
SESSION_ID="$(echo "$INPUT" | jq -r '.session_id // empty' 2>/dev/null || true)"

# Fallback: pick most-recently-modified JSONL in projects dir
if [ -z "$SESSION_ID" ]; then
  LATEST="$(ls -1t "${PROJECTS_DIR}"/*.jsonl 2>/dev/null | head -1)"
  [ -z "$LATEST" ] && exit 0
  SESSION_ID="$(basename "$LATEST" .jsonl)"
fi

SRC="${PROJECTS_DIR}/${SESSION_ID}.jsonl"
[ -f "$SRC" ] || exit 0

# Bail silently if NAS not mounted
if ! mountpoint -q ~/archive 2>/dev/null && [ ! -d ~/claude-archives/sessions ]; then
  # try one mkdir; if it fails, we're not mounted
  mkdir -p "$ARCHIVE_ROOT" 2>/dev/null || exit 0
fi

DATE="$(date +%Y-%m-%d)"
DEST_DIR="${ARCHIVE_ROOT}/${DATE}"
mkdir -p "$DEST_DIR" 2>/dev/null || exit 0

DEST="${DEST_DIR}/${SESSION_ID}.jsonl"

# Incremental copy (cp -u: only if source newer; fast on a stable transcript)
cp -u "$SRC" "$DEST" 2>/dev/null || exit 0

# On SessionEnd, also render a human-readable .md
if [ "$EVENT" = "end" ]; then
  MD="${DEST_DIR}/${SESSION_ID}.md"
  python3 - "$DEST" "$MD" <<'PY' 2>/dev/null || true
import json, sys, pathlib
src, dst = sys.argv[1], sys.argv[2]
lines = []
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
                        parts.append(f"[tool_result]")
            text = '\n'.join(p for p in parts if p)
        if not text:
            continue
        ts = r.get('timestamp','')
        lines.append(f"## {role} {ts}\n\n{text}\n")
pathlib.Path(dst).write_text('\n'.join(lines))
PY
fi

# Quiet success log (rotates implicitly via daily folder)
echo "[$(date -Iseconds)] event=${EVENT} sid=${SESSION_ID} -> ${DEST}" >> "$LOG" 2>/dev/null || true

exit 0
