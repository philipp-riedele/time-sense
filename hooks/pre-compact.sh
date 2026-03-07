#!/usr/bin/env bash
TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S %Z")
cat << EOF
{
  "hookSpecificOutput": {
    "hookEventName": "PreCompact",
    "additionalContext": "Current time at compaction: ${TIMESTAMP}. Include this timestamp in the compacted summary so time context is not lost."
  }
}
EOF
exit 0