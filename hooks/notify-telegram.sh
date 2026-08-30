#!/bin/bash
# Telegram notification hook for Claude Code lifecycle events
# Events: Stop, Notification, SubagentStop, TaskCompleted, PreCompact

# Credentials come from the environment — never hardcode. Set these in your shell/profile.
export TELEGRAM_BOT_TOKEN="${TELEGRAM_BOT_TOKEN}"
export TELEGRAM_CHAT_ID="${TELEGRAM_CHAT_ID}"

INPUT=$(cat)
EVENT="${CLAUDE_HOOK_EVENT_NAME:-unknown}"

# Muted while ~/.claude/hooks/.tg-mute exists (Will 2026-07-01: too noisy).
[ -f "$HOME/.claude/hooks/.tg-mute" ] && exit 0

case "$EVENT" in
  Stop)
    ACTIVE=$(echo "$INPUT" | jq -r '.stop_hook_active // false')
    [ "$ACTIVE" = "true" ] && exit 0
    MSG="<b>the system (this node): Task complete</b>"
    ;;
  SubagentStop)
    AGENT=$(echo "$INPUT" | jq -r '.agent_name // "unknown"')
    MSG="<b>this node subagent done:</b> <code>${AGENT}</code>"
    ;;
  TaskCompleted)
    TASK=$(echo "$INPUT" | jq -r '.task_subject // "unknown"')
    MSG="<b>this node task done:</b> <code>${TASK}</code>"
    ;;
  Notification)
    TYPE=$(echo "$INPUT" | jq -r '.notification_type // "unknown"')
    MESSAGE=$(echo "$INPUT" | jq -r '.message // "Needs attention"')
    case "$TYPE" in
      permission_prompt)
        MSG="<b>this node: Approval needed</b>%0A<code>${MESSAGE}</code>" ;;
      idle_prompt)
        MSG="<b>this node: Waiting for input</b>%0A${MESSAGE}" ;;
      *)
        MSG="<b>this node (${TYPE}):</b> ${MESSAGE}" ;;
    esac
    ;;
  PreCompact)
    MSG="<b>this node:</b> Context compacting"
    ;;
  *) exit 0 ;;
esac

curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
  -d chat_id="${TELEGRAM_CHAT_ID}" \
  --data-urlencode "text=${MSG}" \
  -d parse_mode="HTML" > /dev/null 2>&1
exit 0
