# time-sense

**Claude has no internal clock. This plugin gives it one.**

Large language models have zero sense of time. They don't know if seconds or hours have passed between messages. They reuse stale timestamps, say "recently" when they mean "3 days ago", and suggest "waiting a bit longer" for processes that finished 2 hours ago.

`time-sense` fixes this with three hooks and one skill:

## What it does

### Hooks (automatic, no user action needed)

- **Session Start** — Injects current date/time when the session begins. Claude knows what day it is from the first message.
- **Fresh Timestamp** — Injects a fresh timestamp with every user message. Prevents Claude from reusing stale time data across messages.
- **Pre-Compact** — Preserves time context when the conversation is compressed. Long sessions don't lose track of time.

### Skill (activates automatically when time matters)

Teaches Claude to:
- **Always verify** before making time statements (run `date`, don't guess)
- **Calculate durations** explicitly (subtraction, not "a while ago")
- **Know realistic process times** (npm install = 30s-3min, Docker build = 1-10min)
- **Compute transfer times** using actual math (file size / bandwidth)
- **Check status** instead of suggesting "let's wait" when a process should be done
- **Never assume** what time of day it is or how long the user has been working

## Install

```bash
claude plugin install time-sense
```

## The problem this solves

Without this plugin, Claude will:
- Say "it's about 3pm" without checking
- Reuse a timestamp from 40 minutes ago and present it as current
- Tell you to "wait a bit" for a build that finished an hour ago
- Say a log entry is "recent" when it's 3 days old
- Wish you "good morning" at midnight

With this plugin, Claude will:
- Run `date` before any time-related statement
- Calculate exact durations: "This file was modified 2 hours 15 minutes ago"
- Recognize that a 3-minute build started 45 minutes ago is done or failed
- Never make assumptions about your schedule or time of day

## Plugin structure

```
time-sense/
├── .claude-plugin/
│   └── plugin.json
├── hooks/
│   ├── session_start_time.md
│   ├── fresh_timestamp.md
│   └── pre_compact_time.md
├── skills/
│   └── time-sense/
│       └── SKILL.md
└── README.md
```

## License

MIT