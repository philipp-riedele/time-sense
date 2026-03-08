#!/usr/bin/env bash
INPUT=$(cat | tr -d '\r')
TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S %Z")

# Extract conversation ID (jq preferred, grep/sed fallback)
CONV_ID=""
if command -v jq >/dev/null 2>&1; then
  CONV_ID=$(echo "$INPUT" | jq -r '.transcript_path // empty' 2>/dev/null | xargs basename 2>/dev/null | sed 's/\.jsonl$//')
else
  TRANSCRIPT=$(echo "$INPUT" | sed -n 's/.*"transcript_path"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')
  [ -n "$TRANSCRIPT" ] && CONV_ID=$(basename "$TRANSCRIPT" | sed 's/\.jsonl$//')
fi

if [ -n "$CONV_ID" ]; then
  mkdir -p "$HOME/.claude/time-sense-logs"
  echo "UserPrompt|${TIMESTAMP}" >> "$HOME/.claude/time-sense-logs/${CONV_ID}.log"
fi

cat << EOF
{
  "hookSpecificOutput": {
    "hookEventName": "UserPromptSubmit",
    "additionalContext": "Current time: ${TIMESTAMP}. Any timestamp from a previous message is STALE. If your response involves time (process durations, file ages, build times, scheduling, 'how long ago'), use this timestamp as reference or run date for a fresh one. Never say 'recently' or 'a while ago' — calculate the exact duration."
  }
}
EOF
exit 0
