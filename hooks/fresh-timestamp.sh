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

LOG_DIR="$HOME/.claude/time-sense-logs"
mkdir -p "$LOG_DIR"

# Always log the event (for status tracking)
if [ -n "$CONV_ID" ]; then
  echo "UserPrompt|${TIMESTAMP}" >> "$LOG_DIR/${CONV_ID}.log"
fi

# Extract prompt text for repeat detection
PROMPT=""
if command -v jq >/dev/null 2>&1; then
  PROMPT=$(echo "$INPUT" | jq -r '.prompt // empty' 2>/dev/null)
else
  PROMPT=$(echo "$INPUT" | sed -n 's/.*"prompt"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')
fi

# Check if this is a repeated prompt (likely a loop iteration)
LAST_PROMPT_FILE="$LOG_DIR/.last-prompt"
IS_REPEAT="false"
if [ -f "$LAST_PROMPT_FILE" ]; then
  LAST_PROMPT=$(cat "$LAST_PROMPT_FILE" 2>/dev/null)
  [ "$LAST_PROMPT" = "$PROMPT" ] && IS_REPEAT="true"
fi
printf '%s' "$PROMPT" > "$LAST_PROMPT_FILE"

# Read config
INJECT_ON_REPEAT="true"
if [ -f "$HOME/.claude/time-sense.conf" ]; then
  CFG_VAL=$(tr -d '\r' < "$HOME/.claude/time-sense.conf" | sed -n 's/^inject_on_repeat=//p')
  [ -n "$CFG_VAL" ] && INJECT_ON_REPEAT="$CFG_VAL"
fi

if [ "$IS_REPEAT" = "true" ] && [ "$INJECT_ON_REPEAT" != "true" ]; then
  # Skip injection but output valid empty response
  echo '{}'
else
  cat << EOF
{
  "hookSpecificOutput": {
    "hookEventName": "UserPromptSubmit",
    "additionalContext": "Current time: ${TIMESTAMP}. Any timestamp from a previous message is STALE. If your response involves time (process durations, file ages, build times, scheduling, 'how long ago'), use this timestamp as reference or run date for a fresh one. Never say 'recently' or 'a while ago' — calculate the exact duration."
  }
}
EOF
fi
exit 0
