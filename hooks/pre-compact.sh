#!/usr/bin/env bash
INPUT=$(cat)
TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S %Z")
CONV_ID=$(echo "$INPUT" | jq -r '.transcript_path // empty' 2>/dev/null | xargs basename 2>/dev/null | sed 's/\.jsonl$//')

MSG="Current time at compaction: ${TIMESTAMP}."

if [ -n "$CONV_ID" ]; then
  LOG_FILE="$HOME/.claude/time-sense-logs/${CONV_ID}.log"
  mkdir -p "$HOME/.claude/time-sense-logs"
  echo "PreCompact|${TIMESTAMP}" >> "$LOG_FILE"

  if [ -f "$LOG_FILE" ]; then
    TOTAL=$(wc -l < "$LOG_FILE" | tr -d ' ')
    COMPACTIONS=$(grep -c "PreCompact" "$LOG_FILE" || echo "0")
    SESSIONS=$(grep "SessionStart" "$LOG_FILE" | wc -l | tr -d ' ')
    FIRST_EVENT=$(head -1 "$LOG_FILE" | cut -d'|' -f3)
    [ -z "$FIRST_EVENT" ] && FIRST_EVENT=$(head -1 "$LOG_FILE" | cut -d'|' -f2)

    MODE="full"
    [ -f "$HOME/.claude/time-sense.conf" ] && MODE=$(grep -oP 'inject_timeline=\K\S+' "$HOME/.claude/time-sense.conf" 2>/dev/null || echo "full")

    if [ "$MODE" = "summary" ]; then
      USER_PROMPTS=$(grep -c "UserPrompt" "$LOG_FILE" || echo "0")
      STRUCTURAL_EVENTS=$(grep -E "^(SessionStart|PreCompact)" "$LOG_FILE")
      MSG="Compaction #${COMPACTIONS} at ${TIMESTAMP}. Conversation first started at ${FIRST_EVENT}. Total sessions: ${SESSIONS}. Total compactions: ${COMPACTIONS}. Total user messages: ${USER_PROMPTS}. Total events logged: ${TOTAL}. Session starts and compaction timestamps (structural events):
${STRUCTURAL_EVENTS}"
    else
      TIMELINE=$(cat "$LOG_FILE")
      MSG="Compaction #${COMPACTIONS} at ${TIMESTAMP}. Conversation first started at ${FIRST_EVENT}. Total sessions: ${SESSIONS}. Total events logged: ${TOTAL}. Full conversation timeline (preserve ALL timestamps in the compacted summary so temporal context across sessions and compactions is never lost):
${TIMELINE}"
    fi
  fi
fi

printf '%s' "$MSG" | jq -Rs '{systemMessage: .}'
exit 0
