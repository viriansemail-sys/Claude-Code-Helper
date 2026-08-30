# Claude Code — New User Cheat Sheet

## Getting around
| Keys / command | What it does |
|---|---|
| `claude` | Start Claude Code in the current folder |
| `claude -c` | Continue your last conversation |
| `Shift+Tab` (twice) | **Plan Mode** — Claude plans before touching code. Use it! |
| `Esc` | Interrupt Claude mid-task |
| `/clear` | Fresh context (do this between unrelated tasks) |
| `/help` | Built-in help |
| `/config` | Settings (theme, model, etc.) |
| `!<command>` | Run a shell command yourself, output lands in the chat |
| `#<note>` | Quickly add a memory/instruction |

## The workflow that works
1. **Describe the goal**, not the steps: "Build a landing page for a health-tracking app with a hero, features section, and signup form."
2. Use **Plan Mode** for anything with more than a couple of steps.
3. Review the plan → say "go".
4. Ask Claude to **run and verify** its own work ("run it and show me").
5. `/clear` and move to the next thing.

## Best skills in this kit for web + AI dev
| Skill | Use it for |
|---|---|
| `/frontend-design` | Distinctive, production-grade UI — not generic AI pages |
| `/code-review` | Review code after every build |
| `/research <topic>` | Web research with sources (auto-deepens) |
| `/github-readme` | Generate a great README |
| `/repo-scaffold` | Scaffold a new project properly |
| `/html-report-builder` | Beautiful HTML reports from data |
| `superpowers:brainstorming` | Requirements discovery before building |
| `superpowers:systematic-debugging` | When something breaks — reproduce → isolate → fix |
| `superpowers:test-driven-development` | TDD discipline |

## Best agents (Claude dispatches these when you ask)
- **backend-architect / fastapi-pro / django-pro** — API and backend design
- **frontend-developer** — React 19 / Next.js components
- **security-auditor** — check your app before sharing it
- **debugger** — root-cause analysis
- **docs-architect / tutorial-engineer** — documentation

## CLAUDE.md — your project brain
Create a `CLAUDE.md` in any project root. Claude reads it every session. Put in it:
- What the project is and the tech stack
- Commands to build/test/run
- Rules ("never touch the prod config", "always use TypeScript strict")

Or run `/init` and Claude writes one for you.

## MCP — plug in external tools
```bash
claude mcp add context7 -- npx -y @upstash/context7-mcp   # live library docs
claude mcp list
```

## Golden rules
- **Plan Mode for anything real.** Cheap insurance.
- **Small, verified steps** beat one giant prompt.
- **Ask Claude to prove it** — "run the tests", "curl the endpoint", "screenshot it".
- **Never paste secrets** into prompts or commit them to repos.
- When stuck: `/clear`, restate the goal in one sentence, try again.
