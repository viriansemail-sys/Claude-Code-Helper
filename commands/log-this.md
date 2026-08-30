# Log This Session

Write a daily log entry for today's session.

1. Read the current daily log at `~/.claude/projects/-home-system/memory/daily/$(date +%Y-%m-%d).md`
2. If it exists, APPEND to it. If not, create it.
3. Log format:
   - Session timestamp
   - Bullet points of what was done
   - Any decisions made
   - Any files created or modified
   - Any issues or blockers
   - Next steps
4. Update any relevant thread files in `~/.claude/projects/-home-system/memory/threads/`
5. Keep entries concise — bullets, not paragraphs
