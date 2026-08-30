---
description: View the user's empire ideas board (canonical at ~/studio/ideas/)
---

The canonical ideas board lives at `~/studio/ideas/IDEAS.md` — visible to every Claude Code instance via the studio share.

## What this command does

1. Read `~/studio/ideas/IDEAS.md` and display its full contents
2. List any other files in `~/studio/ideas/` (playbooks, drafts, sub-docs)
3. If the user passes an argument, treat it as a new idea to capture — append a dated entry to `IDEAS.md` under `## Active Ideas` and confirm what was added

## Canonical Location

`~/studio/ideas/`
- `IDEAS.md` — the user's empire ideas board (master list)
- `2026-04-23_bigfoot-hcm-linkedin-playbook.md` — LinkedIn HCM cryptid content playbook
- `_assets/` — supporting assets (architecture flowcharts etc — these may live at `~/studio/platform/docs/architecture/` instead)

## Hard rule — One Ideas List Only

There is exactly ONE ideas board: `~/studio/ideas/IDEAS.md`. Never write a second IDEAS.md anywhere else. If a duplicate is found at `~/shared-users/will/ideas/`, `~/projects/_drafts/creative/ideas/`, or any other path, hash-compare and consolidate into the canonical, then nuke the duplicate.

## Cross-instance availability

Because `~/studio/` is the studio share mounted on every node (node-a, the system, Engineering, node-c, node-b, <your-node>), every Claude Code instance reading `~/studio/ideas/IDEAS.md` sees the same content. No rsync needed — the file IS the source of truth.
