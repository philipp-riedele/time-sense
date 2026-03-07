#!/usr/bin/env bash
TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S %Z")
echo "${TIMESTAMP}" > /tmp/claude-time-sense-session-start
cat << EOF
{
  "systemMessage": "Current time: ${TIMESTAMP}. This is your temporal anchor for this session. Before any time-related statement, always run date to get a fresh timestamp. Never reuse old timestamps. Never guess what time it is."
}
EOF
exit 0