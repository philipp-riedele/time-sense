#!/usr/bin/env bash
TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S %Z")
cat << EOF
{
  "hookSpecificOutput": {
    "hookEventName": "UserPromptSubmit",
    "additionalContext": "Current time: ${TIMESTAMP}. Any timestamp from a previous message is STALE. If your response involves time (process durations, file ages, build times, scheduling, 'how long ago'), use this timestamp as reference or run date for a fresh one. Never say 'recently' or 'a while ago' — calculate the exact duration."
  }
}
EOF
exit 0