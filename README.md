# 🐝 Claude Code Helper
### by HIVE AI

![License: MIT](https://img.shields.io/badge/license-MIT-ffc30b?style=flat-square&labelColor=1a1a1a) ![Skills](https://img.shields.io/badge/skills-114-ffc30b?style=flat-square&labelColor=1a1a1a) ![Agents](https://img.shields.io/badge/agents-30-ffc30b?style=flat-square&labelColor=1a1a1a) ![Made with Claude Code](https://img.shields.io/badge/made%20with-Claude%20Code-1a1a1a?style=flat-square&labelColor=ffc30b)

A starter kit for getting productive with [Claude Code](https://claude.com/claude-code) fast — a full working library of **skills**, **agents**, **slash commands**, and **hooks** from a heavily-customized production setup, plus install instructions and a cheat sheet for new users.

Great for front-end work (websites, React, UI design), back-end work (APIs, Python, databases), and AI projects.

---

## 1. Install Claude Code

**macOS / Linux / WSL:**
```bash
curl -fsSL https://claude.ai/install.sh | bash
```

**Or via npm (needs Node 18+):**
```bash
npm install -g @anthropic-ai/claude-code
```

**Windows (PowerShell):**
```powershell
irm https://claude.ai/install.ps1 | iex
```

Then start it in any folder:
```bash
cd my-project
claude
```
First run walks you through login (Claude Pro/Max subscription or API key both work).

## 2. Install this kit

Copy the pieces you want into your `~/.claude/` directory:

```bash
git clone https://github.com/<you>/Claude-Code-Helper.git
cd Claude-Code-Helper
mkdir -p ~/.claude
cp -r skills agents commands hooks ~/.claude/
cp keybindings.json ~/.claude/          # optional
cp CLAUDE.starter.md ~/.claude/CLAUDE.md  # optional — edit it to fit you!
```

Restart `claude` and everything is live:
- **Skills** → type `/` to see them (e.g. `/frontend-design`, `/research`, `/code-review`)
- **Agents** → Claude dispatches these specialists automatically (backend, debugging, security…)
- **Commands** → custom slash commands
- **Hooks** → require wiring in `settings.json` (see `settings.reference.json` for how a full hook setup looks — adapt paths before using!)

## 3. The Cheat Sheet

- `CHEATSHEET.md` — read it once, keep it handy.
- `hooks/new-user-cheatsheet.sh` — optional hook that prints the cheat sheet at the start of **every session**. Wire it in `~/.claude/settings.json`:

```json
{
  "hooks": {
    "SessionStart": [
      { "hooks": [ { "type": "command", "command": "~/.claude/hooks/new-user-cheatsheet.sh" } ] }
    ]
  }
}
```

## 4. MCP servers (superpowers via external tools)

See `mcp.example.json` — copy to your project as `.mcp.json` and fill in your own values. Good starters: `filesystem`, `context7` (live library docs), `memory`, `sequential-thinking`.

```bash
claude mcp add context7 -- npx -y @upstash/context7-mcp
```

## 5. What's inside

| Folder | Count | What it is |
|---|---|---|
| `skills/` | 114 | Slash-invocable workflows (research, code review, frontend design, debugging, reports…) |
| `agents/` | 30 | Specialist subagents (backend, Python, security, RAG, Docker, GitHub ops…) |
| `commands/` | 56 | Custom slash commands |
| `hooks/` | 27 | Automation scripts (session start, guards, audits) — reference; adapt paths |
| `settings.reference.json` | — | Example of full hook wiring (paths are machine-specific — adapt) |
| `CLAUDE.starter.md` | — | A clean starter for your own global instructions |
| `CHEATSHEET.md` | — | New-user command cheat sheet |
| `mcp.example.json` | — | MCP server config template (no secrets) |

> Note: some skills/agents reference a specific home-lab environment (node names, NAS paths). They still work as templates — the interesting ones for general dev are marked in the cheat sheet.

## 6. Five habits that make Claude Code great

1. **Plan first** — press `Shift+Tab` twice for Plan Mode on anything non-trivial.
2. **Use `/` skills** — don't hand-roll what a skill already does.
3. **Write a `CLAUDE.md`** — per-project instructions Claude reads every session.
4. **Let agents work** — ask Claude to "dispatch a subagent" for big searches/reviews.
5. **`/clear` between unrelated tasks** — a fresh context is a smarter Claude.

---

🐝 **HIVE AI** — tools that work, from a hive that ships. MIT licensed; see `ATTRIBUTIONS.md` for bundled community packs.
