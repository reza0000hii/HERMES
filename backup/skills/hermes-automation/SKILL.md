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

## Cron Delivery Formatting

By default, cron deliveries include technical headers:
```
Cronjob Response: Job Name
(job_id: xxxxxxxx)
-------------
```
Suppress with: `hermes config set cron.wrap_response false`
This delivers only the clean content without headers/footers.

### Self-Improvement Notifications

The agent also emits "Self-improvement review: Patched SKILL.md..." messages after background skill/memory reviews. Suppress with:
```
hermes config set display.memory_notifications off
```
This stops all background review notifications (memory saves, skill patches) from appearing in chat. The reviews still run silently.

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

## SPA Data Extraction Pattern

For React/Vue SPAs backed by Supabase (e.g. fundbase.ir, Iranian financial platforms):
1. Download JS bundle from the site
2. Extract Supabase project ID and anon key from the JS
3. Query REST API directly with the credentials
- See `references/supabase-spa-extraction.md` for full worked example

## News Monitoring Pattern

1. Create LLM-driven cron job (no_agent=False)
2. Prompt instructs agent to search web for specific topics
3. Add conditional: "If nothing new, stay silent"
4. Use deliver="origin" to send to user chat
5. Schedule by urgency: breaking news every 1h, general every 6-24h
6. For financial events: daily scan at 10AM, auto-create one-time alerts 1h before events
7. For market-specific monitoring (e.g. Iran TSE): schedule only on market days — Iran market runs Saturday–Wednesday (Thu/Fri off). Use cron `0 9 * * 6,0,1,2,3` for "12:30 Iran time, market days only"

## Financial Calendar Smart Alert Pattern

Instead of polling every hour, use a single daily scan that creates sub-alerts:
1. Daily at 10AM Iran: full scan of economic calendar
2. If no events → report "nothing today" and stop
3. If events exist between market hours (11:00–19:00 Iran) → create one-time cron jobs (`repeat=1`) 1 hour before each event
4. Requires `enabled_toolsets=["terminal","cron"]` so agent can create sub-cron jobs

## Script-Based Data Report Pattern

For periodic data reports (e.g. gold bubble analysis, market summaries):
1. Write a Python script that queries an API and formats output
2. Script outputs `report:` header followed by structured lines
3. Place in `~/.hermes/scripts/` with descriptive name
4. Create cron job with `no_agent=True`, `script=<filename>`
5. Use cron expression for market hours only (e.g. `0 9 * * 6,0,1,2,3` for Iran Sat-Wed)

Example script structure:
```python
import json, urllib.request
# Query API, filter data, format output
print("report:")
print("top:")
for d in top_items:
    print(f"  - {d['name']}: {d['value']}")
```

## Shamsi (Iranian) Calendar Pattern

For reminders on Iranian calendar dates (e.g. 27th of each Shamsi month):
1. Install jdatetime: `pip install jdatetime`
2. Write a check script that imports jdatetime and checks `date.today().day`
3. Output reminder text only if the day matches; stay silent otherwise
4. Use `no_agent=True` with daily cron schedule
5. The script handles the Gregorian→Shamsi conversion automatically

## Reference Files

- `references/session-patterns.md` — Specific session setups, cron job IDs, and user preferences.
- `references/supabase-spa-extraction.md` — How to extract data from React SPAs backed by Supabase.
