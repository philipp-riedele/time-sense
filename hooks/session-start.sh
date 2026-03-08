#!/usr/bin/env bash
INPUT=$(cat | tr -d '\r')
TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S %Z")

# Initialize settings with defaults on first run
if [ ! -f "$HOME/.claude/time-sense.conf" ]; then
  mkdir -p "$HOME/.claude"
  echo "inject_timeline=full" > "$HOME/.claude/time-sense.conf"
fi

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
  echo "SessionStart|${TIMESTAMP}" >> "$HOME/.claude/time-sense-logs/${CONV_ID}.log"
fi

cat << EOF
{
  "hookSpecificOutput": {
    "hookEventName": "SessionStart",
    "additionalContext": "Current time: ${TIMESTAMP}. This is your temporal anchor for this session. Before any time-related statement, always run date to get a fresh timestamp. Never reuse old timestamps. Never guess what time it is."
  }
}
EOF
exit 0
