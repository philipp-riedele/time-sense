---
name: setup
description: "node | bash — Runtime"
arguments:
  - name: runtime
    description: "Runtime to use: 'node' or 'bash'. Omit to show current setup."
    required: false
    type: string
---

The user called /time-sense setup: $ARGUMENTS

If "$ARGUMENTS" is "node" or "bash" — this is a SET operation. Go to Step 1a.

If "$ARGUMENTS" is empty or anything else — this is a SHOW operation. Go to Step 1b.

**Step 1a — SET runtime:**

Use "$ARGUMENTS" directly as RUNTIME.

Copy the matching pre-built hooks.json over the active one. Do NOT write or modify JSON — only copy:
```bash
cp "${CLAUDE_PLUGIN_ROOT}/hooks/hooks.${RUNTIME}.json" "${CLAUDE_PLUGIN_ROOT}/hooks/hooks.json"
```

Update time-sense.conf:
```bash
EXISTING=$(grep -v "^runtime=" ~/.claude/time-sense.conf 2>/dev/null || true)
echo -e "${EXISTING}\nruntime=${RUNTIME}" | grep -v "^$" > ~/.claude/time-sense.conf
```

Then confirm: "Hook runtime set to **$RUNTIME**. Changes take effect on next session start."

**Step 1b — SHOW current setup:**

```bash
grep "^runtime=" ~/.claude/time-sense.conf 2>/dev/null || echo "runtime=node (default)"
grep "^inject_timeline=" ~/.claude/time-sense.conf 2>/dev/null || echo "inject_timeline=full (default)"
```

Also verify availability:
```bash
node --version 2>/dev/null && echo "node: available" || echo "node: NOT available"
bash --version 2>/dev/null | head -1 && echo "bash: available" || echo "bash: NOT available"
```

Show current runtime, timeline mode, availability, and ask if the user wants to change anything.
