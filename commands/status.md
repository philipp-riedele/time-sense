---
name: status
description: "Plugin health, session stats, log overview"
argument-hint: ""
---

The user called /time-sense:status. Run this diagnostic script and present the results clearly:

```bash
#!/bin/bash
LOG_DIR="$HOME/.claude/time-sense-logs"
CONF="$HOME/.claude/time-sense.conf"
HOOKS_JSON="${CLAUDE_PLUGIN_ROOT}/hooks/hooks.json"

echo "=== TIME-SENSE STATUS ==="
echo ""

# --- CONFIG ---
echo "## Config"
if [ -f "$CONF" ]; then
  MODE=$(grep "^inject_timeline=" "$CONF" 2>/dev/null | cut -d= -f2)
  echo "Mode: ${MODE:-full (default)}"
  echo "Config: $CONF"
else
  echo "Mode: full (default)"
  echo "Config: not found (using defaults)"
fi

# Runtime detection
if [ -f "$HOOKS_JSON" ]; then
  if grep -q '\.mjs' "$HOOKS_JSON" 2>/dev/null; then
    echo "Runtime: node"
  else
    echo "Runtime: bash"
  fi
else
  echo "Runtime: unknown (hooks.json not found)"
fi
echo ""

# --- SESSION ---
echo "## Current Session"

# Find current session log by most recent modification
if [ -d "$LOG_DIR" ]; then
  CURRENT_LOG=$(ls -t "$LOG_DIR"/*.log 2>/dev/null | head -1)
  if [ -n "$CURRENT_LOG" ]; then
    SESSION_ID=$(basename "$CURRENT_LOG" .log)
    FIRST_LINE=$(head -1 "$CURRENT_LOG")
    FIRST_TS=$(echo "$FIRST_LINE" | cut -d'|' -f2 | xargs)

    PROMPTS=$(grep -c "UserPrompt" "$CURRENT_LOG")
    COMPACTIONS=$(grep -c "PreCompact" "$CURRENT_LOG")
    TOTAL_EVENTS=$(wc -l < "$CURRENT_LOG")

    echo "Session ID: ${SESSION_ID:0:8}..."
    echo "Started: $FIRST_TS"
    echo "Prompts: $PROMPTS"
    echo "Compactions: $COMPACTIONS"
    echo "Total events: $TOTAL_EVENTS"

    LAST_LINE=$(tail -1 "$CURRENT_LOG")
    LAST_TS=$(echo "$LAST_LINE" | cut -d'|' -f2 | xargs)
    echo "Last event: $LAST_TS"
  else
    echo "No session logs found"
  fi
else
  echo "Log directory does not exist"
fi
echo ""

# --- LOGS ---
echo "## Log Files"
if [ -d "$LOG_DIR" ]; then
  LOG_COUNT=$(ls "$LOG_DIR"/*.log 2>/dev/null | wc -l)
  if [ "$LOG_COUNT" -gt 0 ]; then
    TOTAL_SIZE=$(du -sh "$LOG_DIR" 2>/dev/null | cut -f1)
    OLDEST=$(ls -tr "$LOG_DIR"/*.log 2>/dev/null | head -1)
    OLDEST_DATE=$(stat -c %y "$OLDEST" 2>/dev/null || stat -f "%Sm" -t "%Y-%m-%d %H:%M:%S" "$OLDEST" 2>/dev/null)
    OLDEST_DATE=$(echo "$OLDEST_DATE" | cut -d. -f1)
    NEWEST=$(ls -t "$LOG_DIR"/*.log 2>/dev/null | head -1)
    NEWEST_DATE=$(stat -c %y "$NEWEST" 2>/dev/null || stat -f "%Sm" -t "%Y-%m-%d %H:%M:%S" "$NEWEST" 2>/dev/null)
    NEWEST_DATE=$(echo "$NEWEST_DATE" | cut -d. -f1)

    echo "Total logs: $LOG_COUNT"
    echo "Total size: $TOTAL_SIZE"
    echo "Oldest: $OLDEST_DATE"
    echo "Newest: $NEWEST_DATE"
    echo "Location: $LOG_DIR"
  else
    echo "No log files found in $LOG_DIR"
  fi
else
  echo "Log directory does not exist: $LOG_DIR"
fi
echo ""

# --- HEALTH CHECK ---
echo "## Health"
ERRORS=0

# Check log dir
if [ -d "$LOG_DIR" ]; then
  echo "[OK] Log directory exists"
else
  echo "[FAIL] Log directory missing: $LOG_DIR"
  ERRORS=$((ERRORS + 1))
fi

# Check hooks.json
if [ -f "$HOOKS_JSON" ]; then
  # Validate JSON syntax
  if node -e "JSON.parse(require('fs').readFileSync('$HOOKS_JSON','utf8'))" 2>/dev/null; then
    echo "[OK] hooks.json valid"
  elif python3 -c "import json; json.load(open('$HOOKS_JSON'))" 2>/dev/null; then
    echo "[OK] hooks.json valid"
  else
    echo "[WARN] hooks.json may be invalid"
    ERRORS=$((ERRORS + 1))
  fi
else
  echo "[FAIL] hooks.json not found"
  ERRORS=$((ERRORS + 1))
fi

# Check hook files exist
if grep -q '\.mjs' "$HOOKS_JSON" 2>/dev/null; then
  for HOOK in session-start.mjs fresh-timestamp.mjs pre-compact.mjs; do
    if [ -f "${CLAUDE_PLUGIN_ROOT}/hooks/$HOOK" ]; then
      echo "[OK] $HOOK exists"
    else
      echo "[FAIL] $HOOK missing"
      ERRORS=$((ERRORS + 1))
    fi
  done
else
  for HOOK in session-start.sh fresh-timestamp.sh pre-compact.sh; do
    if [ -f "${CLAUDE_PLUGIN_ROOT}/hooks/$HOOK" ]; then
      echo "[OK] $HOOK exists"
    else
      echo "[FAIL] $HOOK missing"
      ERRORS=$((ERRORS + 1))
    fi
  done
fi

# Check node availability (if node runtime)
if grep -q '\.mjs' "$HOOKS_JSON" 2>/dev/null; then
  if node --version >/dev/null 2>&1; then
    echo "[OK] Node.js $(node --version)"
  else
    echo "[FAIL] Node.js not available but runtime is set to node"
    ERRORS=$((ERRORS + 1))
  fi
fi

# Check last log entry is parseable
if [ -n "$CURRENT_LOG" ] && [ -f "$CURRENT_LOG" ]; then
  LAST=$(tail -1 "$CURRENT_LOG")
  if echo "$LAST" | grep -qE "^(SessionStart|UserPrompt|PreCompact)\|"; then
    echo "[OK] Last log entry valid"
  else
    echo "[WARN] Last log entry may be malformed: $LAST"
    ERRORS=$((ERRORS + 1))
  fi
fi

echo ""
if [ "$ERRORS" -eq 0 ]; then
  echo "Status: ALL OK"
else
  echo "Status: $ERRORS issue(s) found"
fi
```

Present the output in a clean, readable format. Calculate the session duration from the start time to now. If there are any FAIL results in the health check, explain what might be wrong and how to fix it.
