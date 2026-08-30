#!/usr/bin/env bash
# PreToolUse hook (matcher: Agent) — HARD BLOCK general-purpose subagents.
# the user's hard rule 2026-05-29: Claude may ONLY spawn SPECIALIZED agents.
# Omitting subagent_type (defaults to general-purpose) is also blocked.
# Exit 2 = block the tool call + surface stderr to Claude.

input="$(cat)"

subagent_type="$(printf '%s' "$input" | python3 -c '
import sys, json
try:
    d = json.load(sys.stdin)
    ti = d.get("tool_input", {}) or {}
    print((ti.get("subagent_type") or "").strip())
except Exception:
    print("")
' 2>/dev/null)"

case "$subagent_type" in
  ""|general-purpose|general|claude|Explore|Plan)
    cat >&2 <<'EOF'
BLOCKED — HARD RULE (Will, 2026-05-29): general-purpose subagents are not allowed.
You MUST set subagent_type to a SPECIALIZED agent and re-issue the call. Pick the closest fit:
  • deep-researcher        — web research, model/tech surveys, synthesis
  • rag-knowledge-architect— Qdrant, embeddings, chunking, retrieval
  • python-systems-engineer— FastAPI/async services, Redis, pipelines
  • security-architect     — hardening, secrets, TLS, VLANs, lockdown
  • nvidia-cuda-engineer   — GPU/CUDA/TensorRT/vLLM
  • inference-architect    — model serving, VRAM budgets, quantization
  • docker-ops             — container lifecycle/troubleshooting
  • n8n-architect          — n8n workflows
  • home-automation-engineer — Home Assistant / IoT / ESPHome
  • mcp-protocol-architect — MCP server/tool design
  • trainer / data-prep    — fine-tuning / dataset prep
  • debugger               — root-cause analysis
  • assistant-core           — infra monitoring / self-heal
  • content-architect      — content/strategy
Re-issue with subagent_type set to one of these (or another specialized agent), never general-purpose.
EOF
    exit 2
    ;;
  *)
    exit 0
    ;;
esac
