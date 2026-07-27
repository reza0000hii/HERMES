---
name: hermes-automation
description: "Cron jobs, backups, monitoring, and reminders patterns."
version: 1.0.0
author: Hermes Agent
license: MIT
metadata:
  hermes:
    tags: [cron, automation, backup, monitoring, reminders]
---

# Hermes Automation

Patterns for setting up durable automated workflows: cron jobs, backup scripts, news monitors, reminders, and periodic tasks.

## Cron Job Creation

### Script-Based Jobs (no_agent=True)

For jobs that just run a script and deliver stdout:

- Script MUST live in `~/.hermes/scripts/` and use relative filename only
- Absolute or home-relative paths are rejected by the runtime
- Copy your script there first, then reference by filename

### LLM-Driven Jobs (no_agent=False, default)

For jobs that need web search, reasoning, or conditional logic:

- Use `deliver="origin"` to send results to the current chat
- Use `deliver="local"` for fire-and-forget logging only
- `repeat=1` for one-shot reminders (runs once then auto-removes)
- `context_from=[job_id]` to chain jobs (A output feeds B)

### Schedule Formats

- Duration: "30m", "2h", "every 6h" for periodic checks
- Cron expression: "0 9 * * *" for same time daily
- ISO timestamp: "2026-07-27T14:30:00" for one-shot reminders
- Phrase: "every monday 9am" for weekly tasks

## Pitfalls

### Unicode Injection Block

Persian/Arabic text in cron prompts triggers injection detection (U+200C Zero Width Non-Joiner). Write cron prompts in English. The agent final response can still be in user language.

### GitHub Push Protection

GitHub blocks pushes containing PATs in any file including binary (SQLite). Exclude state.db, auth.json, .env from backups. Add to .gitignore.

### Script Path Resolution

cronjob with no_agent=True rejects absolute script paths. Always use ~/.hermes/scripts/ with bare filename.

### Missing Model Configuration

LLM-driven cron jobs (no_agent=False) fail with "has no model configured" if model/provider not set. Always pass `model={"model": "mimohermes", "provider": "openai-api"}` when creating LLM-driven cron jobs. Script-only jobs (no_agent=True) do not need this.

## Backup Pattern

Include: memories/, skills/, cron/, sessions/, config.yaml, SOUL.md, kanban.db
Exclude: state.db (tokens), auth.json, .env, cache/, logs/, audio_cache/, image_cache/

## News Monitoring Pattern

1. Create LLM-driven cron job (no_agent=False)
2. Prompt instructs agent to search web for specific topics
3. Add conditional: "If nothing new, stay silent"
4. Use deliver="origin" to send to user chat
5. Schedule by urgency: breaking news every 1h, general every 6-24h

## Reference Files

- `references/session-patterns.md` — Specific session setups, cron job IDs, and user preferences.
