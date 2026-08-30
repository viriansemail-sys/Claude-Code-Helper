---
name: notes
description: Add, view, and search persistent project notes on NAS. Ensures knowledge persists across sessions. Use when Will says /notes, "add a note", "project notes", "what did we do on X".
user_invocable: true
trigger: /notes
---

# /notes — Persistent Project Notes

You are the assistant, managing persistent project notes stored on the NAS. Notes survive across sessions and give future-you (and Will) full context on any project.

## Storage

All notes live at: `~/projects/<project>/NOTES.md`

## Commands

### `/notes add <project> <note>`

Append a timestamped note to the project's NOTES.md.

**Steps:**
1. Normalize the project name to lowercase with underscores (e.g., "Cozy Cabin Jazz" -> "cozy_cabin_jazz")
2. If `~/projects/<project>/` doesn't exist, create it with `mkdir -p`
3. If `NOTES.md` doesn't exist, create it with this header:
   ```
   # <Project Name> — Project Notes

   Persistent notes for the <Project Name> project.
   Auto-managed by the assistant via `/notes` skill.

   ---

   ```
4. Append the note in this format:
   ```
   ## YYYY-MM-DD HH:MM — <note title or summary>

   <note body — the full content Will provided>

   ---

   ```
5. Use the current timestamp (date +"%Y-%m-%d %H:%M")
6. Confirm: "Note added to <project>. Total entries: N"

### `/notes show <project>`

Display a project's notes.

**Steps:**
1. Normalize project name
2. Check if `~/projects/<project>/NOTES.md` exists
3. If not: respond "No notes found for **<project>**. Start with `/notes add <project> <your note>`."
4. If yes: read and display the file contents

### `/notes search <keyword>`

Search across ALL project notes for a keyword.

**Steps:**
1. Use Grep to search for the keyword across all `~/projects/*/NOTES.md` files
2. For each match, extract:
   - Project name (from the path)
   - The `## YYYY-MM-DD` header of the matching entry (search backwards from match line)
   - The matching line with context (-C 2)
3. Format results as:
   ```
   **<project>** — YYYY-MM-DD HH:MM
   > matching line with context
   ```
4. If no results: "No notes matching '**<keyword>**' found across any project."

### `/notes list`

List all projects that have notes.

**Steps:**
1. Find all `NOTES.md` files in `~/projects/*/`
2. For each file:
   - Extract project name from path
   - Count entries (count lines matching `^## `)
   - Get the last entry date (last line matching `^## YYYY-MM-DD`)
3. Display as a table:
   ```
   | Project | Entries | Last Updated |
   |---------|---------|--------------|
   | cozy_cabin_jazz | 5 | 2026-03-13 |
   ```
4. If no projects have notes: "No project notes found yet. Start with `/notes add <project> <your note>`."

## Behavior Notes

- Always normalize project names: lowercase, spaces to underscores, strip special chars
- If Will just says `/notes` with no subcommand, show a brief help message listing the 4 commands
- If Will says something like "add a note about X" or "what did we do on project Y", infer the right command
- Keep confirmations short — Will doesn't need a speech about what you did
- The NAS path `~/projects/` is the canonical root. Never store notes elsewhere.
