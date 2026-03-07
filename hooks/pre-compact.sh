#!/usr/bin/env bash
TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S %Z")
SESSION_START=$(cat /tmp/claude-time-sense-session-start 2>/dev/null || echo "unknown")
cat << EOF
{
  "systemMessage": "Current time at compaction: ${TIMESTAMP}. Session started at: ${SESSION_START}. Include BOTH timestamps in the compacted summary — the session start time anchors how long this session has been running, the compaction time anchors the current moment."
}
EOF
exit 0