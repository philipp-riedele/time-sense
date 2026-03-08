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

MSG="Current time at compaction: ${TIMESTAMP}."

if [ -n "$CONV_ID" ]; then
  LOG_FILE="$HOME/.claude/time-sense-logs/${CONV_ID}.log"
  mkdir -p "$HOME/.claude/time-sense-logs"
  echo "PreCompact|${TIMESTAMP}" >> "$LOG_FILE"

  if [ -f "$LOG_FILE" ]; then
    # Strip \r (Windows carriage returns) once, work from clean data
    LOG_CLEAN=$(tr -d '\r' < "$LOG_FILE")
    TOTAL=$(echo "$LOG_CLEAN" | wc -l | tr -d ' ')
    COMPACTIONS=$(echo "$LOG_CLEAN" | grep -c "PreCompact" || echo "0")
    SESSIONS=$(echo "$LOG_CLEAN" | grep -c "SessionStart" || echo "0")
    FIRST_EVENT=$(echo "$LOG_CLEAN" | head -1 | cut -d'|' -f3)
    [ -z "$FIRST_EVENT" ] && FIRST_EVENT=$(echo "$LOG_CLEAN" | head -1 | cut -d'|' -f2)

    # Read mode from config (portable, no grep -P; strip \r for Windows)
    MODE="full"
    if [ -f "$HOME/.claude/time-sense.conf" ]; then
      MODE=$(tr -d '\r' < "$HOME/.claude/time-sense.conf" | sed -n 's/^inject_timeline=//p')
      [ -z "$MODE" ] && MODE="full"
    fi

    if [ "$MODE" = "summary" ]; then
      USER_PROMPTS=$(echo "$LOG_CLEAN" | grep -c "UserPrompt" || echo "0")
      STRUCTURAL_EVENTS=$(echo "$LOG_CLEAN" | grep -E "^(SessionStart|PreCompact)")
      MSG="Compaction #${COMPACTIONS} at ${TIMESTAMP}. Conversation first started at ${FIRST_EVENT}. Total sessions: ${SESSIONS}. Total compactions: ${COMPACTIONS}. Total user messages: ${USER_PROMPTS}. Total events logged: ${TOTAL}. Session starts and compaction timestamps (structural events):
${STRUCTURAL_EVENTS}"
    else
      MSG="Compaction #${COMPACTIONS} at ${TIMESTAMP}. Conversation first started at ${FIRST_EVENT}. Total sessions: ${SESSIONS}. Total events logged: ${TOTAL}. Full conversation timeline (preserve ALL timestamps in the compacted summary so temporal context across sessions and compactions is never lost):
${LOG_CLEAN}"
    fi
  fi
fi

# Output JSON (jq preferred, python3 fallback, pure-bash last resort)
if command -v jq >/dev/null 2>&1; then
  printf '%s' "$MSG" | jq -Rs '{systemMessage: .}'
elif python3 -c "" 2>/dev/null; then
  printf '%s' "$MSG" | python3 -c "import json,sys; print(json.dumps({'systemMessage': sys.stdin.read()}))"
else
  # Pure bash: escape backslashes, quotes, tabs, and newlines for JSON
  ESCAPED=$(printf '%s' "$MSG" | sed 's/\\/\\\\/g; s/"/\\"/g; s/	/\\t/g' | awk '{if(NR>1) printf "\\n"; printf "%s", $0}')
  printf '{"systemMessage":"%s"}\n' "$ESCAPED"
fi
exit 0
