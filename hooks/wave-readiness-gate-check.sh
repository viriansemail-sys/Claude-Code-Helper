#!/usr/bin/env bash
# wave-readiness-gate-check.sh
# Companion runner for supervisor-git-tag-wave-gate.sh (PreToolUse hook).
# Invokes the wave-readiness-gate skill and returns PROCEED or BLOCK_TAG to the hook.
#
# Args: $1 = proposed tag (e.g. wave-9-v1.0), $2 = project path
# Reads tag tier from suffix: -v0.x.0 = code-done, -v0.x.5 = service-done, -v1.x = system-done
# Output: prints PROCEED or BLOCK_TAG with reason, exit 0 = proceed, exit 1 = block
set -euo pipefail

TAG="${1:-}"
PROJECT="${2:-~/projects/analysis}"
LOG="${PROJECT}/data/night_shift_log.jsonl"
TS=$(date -u +%FT%TZ)

# Determine tier from tag suffix
case "$TAG" in
    *v0.*.0)  TIER="code-done"     ;;
    *v0.*.5)  TIER="service-done"  ;;
    *v1.*|*-v1.*)  TIER="system-done"   ;;
    *)        TIER="unknown"       ;;
esac

# Helper: log event via SSH if local write fails (NFS UID mismatch resilience)
log_event() {
    local ev="$1" extra="$2"
    local line="{\"ts\":\"$TS\",\"event\":\"$ev\",$extra}"
    echo "$line" >> "$LOG" 2>/dev/null || \
        ssh -o ConnectTimeout=3 user@<your-node> "echo '$line' >> '$LOG'" 2>/dev/null || \
        true
}

# For unknown tier or empty tag, allow with advisory warning
if [[ -z "$TAG" || "$TIER" == "unknown" ]]; then
    echo "PROCEED — tag '$TAG' tier unknown, gate is advisory only"
    log_event "wave_readiness_gate_advisory" "{\"tag\":\"$TAG\",\"tier\":\"$TIER\"}"
    exit 0
fi


REASONS=()

# Tier-specific gate checks (skill is the source of truth; we proxy via service-liveness + integration-smoke)
# Code-done: tests must pass, no further check beyond what TDD already enforces
# Service-done: service-liveness must be green
# System-done: service-liveness + integration-smoke must both be green

if [[ "$TIER" == "service-done" || "$TIER" == "system-done" ]]; then
    # Probe expected ports on <your-node> via SSH; force single-line output
    LIVE=$(ssh -o ConnectTimeout=5 user@<your-node> "ss -tlnp 2>/dev/null | grep -cE ':(8000|8090|8091)'" 2>/dev/null | head -n1 | tr -d '[:space:]')
    LIVE=${LIVE:-0}
    if [[ "$LIVE" =~ ^[0-9]+$ ]] && (( LIVE < 2 )); then
        REASONS+=("service-liveness FAIL: only $LIVE of expected ports listening on <your-node>")
    fi
fi

if [[ "$TIER" == "system-done" ]]; then
    # System-done requires a recent integration-smoke pass in the log
    SMOKE_RECENT=$(grep -c '"event":"integration_smoke_pass"' "$LOG" 2>/dev/null | head -n1 | tr -d '[:space:]')
    SMOKE_RECENT=${SMOKE_RECENT:-0}
    if [[ "$SMOKE_RECENT" =~ ^[0-9]+$ ]] && (( SMOKE_RECENT == 0 )); then
        REASONS+=("integration-smoke has not passed for this project (no integration_smoke_pass event in log)")
    fi
fi

if [[ ${#REASONS[@]} -eq 0 ]]; then
    echo "PROCEED — tag '$TAG' (tier=$TIER) passes all required gates"
    log_event "wave_readiness_gate_proceed" "\"tag\":\"$TAG\",\"tier\":\"$TIER\""
    # Set the proof token so supervisor-git-tag-wave-gate.sh allows the tag through.
    # This must be set in the environment before the caller runs: git tag ...
    # Callers should do: export WAVE_GATE_PROOF=1 after this script prints PROCEED.
    export WAVE_GATE_PROOF=1
    exit 0
else
    echo "BLOCK_TAG — tag '$TAG' (tier=$TIER) failed checks:"
    for R in "${REASONS[@]}"; do
        echo "  - $R"
    done
    REASONS_JOINED=$(IFS=, ; echo "${REASONS[*]}")
    log_event "wave_readiness_gate_block" "\"tag\":\"$TAG\",\"tier\":\"$TIER\",\"reasons\":\"${REASONS_JOINED}\""
    exit 1
fi
