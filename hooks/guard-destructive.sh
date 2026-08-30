#!/bin/bash
INPUT=$(cat)
CMD=$(echo "$INPUT" | jq -r '.tool_input.command // ""')
BLOCKED=""

# apt upgrade without nvidia lock
echo "$CMD" | grep -qE 'apt.*(upgrade|dist-upgrade)' && \
  echo "$CMD" | grep -qv 'apt-mark' && \
  BLOCKED="apt upgrade without nvidia lock check"

# Docker destructive ops on named containers
echo "$CMD" | grep -qE 'docker (rm |rmi |volume rm|system prune)' && \
  BLOCKED="docker destructive op"

# rm -rf on critical paths
echo "$CMD" | grep -qE 'rm -rf.*(mnt/nas|opt/system|\.cache/huggingface|home/system)' && \
  BLOCKED="rm -rf on critical path"

# git nukes
echo "$CMD" | grep -qE 'git (reset --hard|push --force|push -f)' && \
  BLOCKED="destructive git op"

[ -z "$BLOCKED" ] && exit 0

# Send Telegram alert
# Credentials come from the environment — never hardcode. Set these in your shell/profile.
TOKEN="${TELEGRAM_BOT_TOKEN}"
CHAT_ID="${TELEGRAM_CHAT_ID}"
MSG="⛔ BLOCKED on this node: ${BLOCKED}%0A<code>${CMD}</code>"
curl -s -X POST "https://api.telegram.org/bot${TOKEN}/sendMessage" \
  -d chat_id="${CHAT_ID}" \
  --data-urlencode "text=${MSG}" \
  -d parse_mode="HTML" > /dev/null 2>&1

exit 2
