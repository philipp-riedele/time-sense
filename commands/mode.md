---
name: mode
description: "full | summary — Timeline injection mode"
arguments:
  - name: mode
    description: "Injection mode: 'full' (all events) or 'summary' (metadata only). Omit to show current mode."
    required: false
    type: string
---

The user called /time-sense with mode: $ARGUMENTS

IMPORTANT: First determine if a valid mode was provided.

**Step 1 — Check if mode is valid:**

If "$ARGUMENTS" is exactly "full" or exactly "summary", this is a SET operation. Go to Step 2a.

If "$ARGUMENTS" is empty, ".mode", or anything other than "full" or "summary", this is a SHOW operation. Go to Step 2b.

**Step 2a — SET mode (only for "full" or "summary"):**

Run this bash command:
```bash
EXISTING=$(grep -v "^inject_timeline=" ~/.claude/time-sense.conf 2>/dev/null || true)
echo -e "${EXISTING}\ninject_timeline=$ARGUMENTS" | grep -v "^$" > ~/.claude/time-sense.conf
```

Then confirm:
- If "full": Timeline injection set to **full** — every event will be included in compaction context.
- If "summary": Timeline injection set to **summary** — only metadata (start time, session/compaction counts) will be included. Individual events are still logged to disk.

**Step 2b — SHOW current mode (no valid mode provided):**

Run this bash command to read the current setting:
```bash
cat ~/.claude/time-sense.conf 2>/dev/null || echo "inject_timeline=full (default)"
```

Then show the user the current mode and ask if they want to switch. The two options are:
- **full** — Every event (SessionStart, UserPrompt, PreCompact) is included in the compaction context.
- **summary** — Only structural events (SessionStart, PreCompact) and metadata counts. Saves context tokens.
