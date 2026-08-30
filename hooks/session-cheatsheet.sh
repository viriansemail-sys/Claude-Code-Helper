#!/bin/bash
# SessionStart hook — prints the system command cheat sheet at the top of every new session.
# Output goes via JSON systemMessage so it shows once and scrolls with the conversation.
# To customize the cheat sheet content, edit the CHEATSHEET heredoc below.

set -e

# Drain stdin (SessionStart payload — we don't need it)
cat >/dev/null

CHEATSHEET=$(cat <<'EOF'

╔═══════════════════════════════════════════════════════════════════╗
║              AISmith AI Studio — Command Cheat Sheet               ║
╚═══════════════════════════════════════════════════════════════════╝

🔬 AISMITH RESEARCH PIPELINE (grounded, multi-agent, anti-hallucination)
  /aismith-research <slug> <question>    Bootstrap grounded research project per v1.0 methodology
                                          → scaffolds folder, deploys supervisor cron, dispatches
                                            specialized subagents, runs verifier (60/60 hit-rate target),
                                            ships final report in MD + DOCX + PDF + HTML

  7-phase pipeline (per project):
    0 — Inventory & hash               cryptographic provenance of corpus
    1 — Parallel extraction            specialized subagents, JSONL claim ledgers
    2 — Contradiction map              team-debugger, hypothesis-driven
    3 — Paper/spec translation         deep-researcher, maturity-tiered
    4 — External grounding             Gemini Deep Research API (Sanjay skill)
    5 — Standing-flag chains           cross-corpus pattern tracking
    6 — Phenomena/comparison tables    taxonomy + heatmaps
    7 — Karpathy falsifiable proposals cheapest experiment per open question
    8 — Visuals (HTML+PNG+SVG+PDF)     5+ ship-ready charts
    9 — Final synthesis + scrub        publishable, NAS-path-free

  Anti-hallucination controls (10):
    citation-or-die · evidence tiers · inline guardrails · forbidden-word grep
    semantic editorializing grep · missing-citation scan · tier-distribution drift
    verifier subagent (deterministic sampling) · contradiction-map cross-check · Telegram alerts

  Canonical worked examples:
    - LLM Benchmark (model eval, quant tradeoffs, latency/quality frontier)
    - Business Case (TAM/SAM/SOM, unit economics, competitive landscape)
  Methodology doc: ~/studio/platform/aismith/methodology/AISMITH-RESEARCH-METHOD-v1.0.{md,docx,pdf}
  Prompt library:  ~/studio/platform/aismith/prompt-library/

🛠  FREQUENTLY USED
  /status      Check all the system nodes & services
  /train       Start/resume model fine-tuning
  /archive     Archive current conversation to NAS
  /notes       Add/view/search persistent project notes (NAS-backed)
  /idea        Drop an idea into the Empire Ideas Board
  /research    Web research / paper analysis (auto-escalates to deep mode)

📁 KEY PATHS
  ~/projects/                Project home
  ~/.claude/memory-ledger/lessons_learned.md   NAS lessons (durable)
  ~/projects/_meta/project-pipeline/README.md        Pipeline docs

EOF
)

# Emit JSON with systemMessage — Claude Code prints this to the user once at session start
jq -n --arg msg "$CHEATSHEET" '{systemMessage: $msg, suppressOutput: true}'
