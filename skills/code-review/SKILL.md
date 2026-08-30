---
name: system-code-review
description: "Mandatory code quality review for the system infrastructure. Dispatches the system-code-reviewer agent to check for spaghetti, connection leaks, error handling, efficiency, and integration correctness. Use after EVERY build task completes. Trigger on: /review, 'review the code', 'check the code', or automatically after any build agent finishes."
---

# /review — the system Code Review

Dispatches the `system-code-reviewer` agent to review recent changes.

## Usage

```
/review                          — Review all recent changes
/review n8n QdZjGLi852B7J9Ep    — Review specific n8n workflow
/review gateway                  — Review gateway main.py changes
```

## What It Checks

1. **Spaghetti** — Single responsibility, clean data flow, readable in 30 seconds
2. **Connections** — pg Client closed in finally, HTTP timeouts, no leaks
3. **Errors** — try/catch everywhere, graceful degradation, logged not swallowed
4. **SQL** — Parameterized, indexed, no N+1, transactional where needed
5. **Efficiency** — No redundant queries, batched where possible, token budget
6. **Target** — Deployed to the RIGHT system (Engineering vs node-a vs <your-node>)
7. **Integration** — Doesn't break existing phases, regression tested

## When To Use

- After EVERY build agent completes (mandatory)
- Before marking any phase as complete
- When debugging reveals unexpected behavior
- Before any phase audit sign-off

## Auto-Dispatch

the assistant should dispatch this agent automatically after every build task. If she forgets, Will should call `/review`.
