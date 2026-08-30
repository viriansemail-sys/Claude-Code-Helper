#!/bin/bash
# SessionStart hook — prints a Claude Code cheat sheet at the top of every new session.
# Wire it in ~/.claude/settings.json under hooks.SessionStart (see README.md).
# Edit the heredoc below to customize.

set -e

# Drain stdin (SessionStart payload — not needed)
cat >/dev/null

CHEATSHEET=$(cat <<'EOF'

╔═══════════════════════════════════════════════════════════════════╗
║                 Claude Code — Quick Cheat Sheet                    ║
╚═══════════════════════════════════════════════════════════════════╝

⌨️  ESSENTIALS
  Shift+Tab ×2   Plan Mode — Claude plans before coding (use for anything real)
  Esc            Interrupt Claude mid-task
  /clear         Fresh context between unrelated tasks
  ! <cmd>        Run a shell command yourself
  /help /config  Help & settings

🛠  TOP SKILLS (type / to browse all)
  /frontend-design   Production-grade UI, not generic AI pages
  /code-review       Review code after every build
  /research <topic>  Web research with sources
  /repo-scaffold     Start a new project right
  /github-readme     Generate a great README

🧠 WORKFLOW
  1. Describe the GOAL, not the steps
  2. Plan Mode → review → "go"
  3. Ask Claude to run + verify its own work
  4. /clear and move on

📌 TIPS
  • Create CLAUDE.md in your project root (or run /init) — Claude reads it every session
  • Never paste secrets into prompts
  • Small verified steps beat one giant prompt

EOF
)

jq -n --arg msg "$CHEATSHEET" '{systemMessage: $msg, suppressOutput: true}'
