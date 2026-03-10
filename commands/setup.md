---
name: setup
description: "node | bash — Runtime"
argument-hint: "[node | bash]"
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

Then confirm: "Hook runtime set to **$RUNTIME**. Changes take effect on next session start."

**Step 1b — SHOW current setup:**

Detect current runtime by reading hooks.json:
```bash
grep -q "\.mjs" "${CLAUDE_PLUGIN_ROOT}/hooks/hooks.json" && echo "runtime=node" || echo "runtime=bash"
grep "^inject_timeline=" ~/.claude/time-sense.conf 2>/dev/null || echo "inject_timeline=full (default)"
```

Also verify availability:
```bash
node --version 2>/dev/null && echo "node: available" || echo "node: NOT available"
bash --version 2>/dev/null | head -1 && echo "bash: available" || echo "bash: NOT available"
```

Show current runtime, timeline mode, availability, and ask if the user wants to change anything.
