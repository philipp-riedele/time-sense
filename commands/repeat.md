---
name: repeat
description: "on | off — Inject timestamps on repeated prompts (loops)"
argument-hint: "[on | off]"
arguments:
  - name: setting
    description: "Enable or disable timestamp injection on repeated/loop prompts. Omit to show current setting."
    required: false
    type: string
---

The user called /time-sense:repeat with: $ARGUMENTS

**Step 1 — Check if a valid setting was provided:**

If "$ARGUMENTS" is exactly "on" or exactly "off", this is a SET operation. Go to Step 2a.

If "$ARGUMENTS" is empty or anything else, this is a SHOW operation. Go to Step 2b.

**Step 2a — SET repeat injection:**

Map the value: "on" → "true", "off" → "false".

```bash
VALUE=$( [ "$ARGUMENTS" = "on" ] && echo "true" || echo "false" )
EXISTING=$(grep -v "^inject_on_repeat=" ~/.claude/time-sense.conf 2>/dev/null || true)
echo -e "${EXISTING}\ninject_on_repeat=$VALUE" | grep -v "^$" > ~/.claude/time-sense.conf
```

Then confirm:
- If "on": Timestamp injection on repeated prompts is **enabled**. Every prompt gets a fresh timestamp, including loop iterations.
- If "off": Timestamp injection on repeated prompts is **disabled**. When the same prompt text appears consecutively (like in a `/loop`), the timestamp is still logged to disk but not injected into the conversation context. This saves tokens in long-running loops.

**Step 2b — SHOW current setting:**

```bash
grep "^inject_on_repeat=" ~/.claude/time-sense.conf 2>/dev/null || echo "inject_on_repeat=true (default)"
```

Show the current setting and explain:
- **on** (default) — Every prompt gets a timestamp injected, including loops. Best for time-sensitive monitoring loops like `/loop 5m check deploy status`.
- **off** — Repeated identical prompts skip injection. The event is still logged to disk (visible in `/time-sense:status`), but Claude doesn't receive the timestamp in context. Best for high-frequency loops where timestamps aren't needed, saving context tokens.

Note: This detection works by comparing consecutive prompt texts. If the prompt text changes between iterations, each one is treated as a new prompt regardless of this setting.
