# Session-Specific Patterns

## Backup to GitHub - Reza's Setup (2026-07-27)

Repository: https://github.com/reza0000hii/HERMES
Token: Classic PAT (ghp_...)

### Backup Script Location
- Original: /data/hermes-backup-repo/backup.sh
- Cron copy: ~/.hermes/scripts/hermes-backup.sh

### Files Excluded (GitHub Push Protection)
state.db contained PAT strings and was blocked by GH013. Added to .gitignore.

### Cron Jobs Created (Final State)
| Job | ID | Schedule |
|-----|----|----------|
| Hermes Backup | 56ca43b8f22c | every 12h |
| Financial Scan + Auto-Alerts | a18e945436e3 | daily 10AM Iran (6:30 UTC) |
| Entertainment News | 43db40997624 | every 24h |
| Iran-US War News | f7408db9f8a0 | daily 11PM Iran (19:30 UTC) |
| Rent/Shop Reminder (Shamsi 27th) | 19fbca5b1a0b | daily check script |
| Trade Analysis (Gregorian 30th) | 5dd839c2789a | 30th of each month |

Removed: Medicine Reminder (one-shot, executed and auto-deleted)

### Financial Calendar Approach
Daily scan at 10AM: if no high-impact USD/EUR events → "no events today" and stop.
If events exist between 11:00-19:00 Iran time → auto-create one-time cron jobs
1 hour before each event using `repeat=1`. Requires `enabled_toolsets=["terminal","cron"]`
so the agent can create sub-cron jobs.

### News Sources (User Preference)
- War: Reuters, BBC, Al Jazeera, AP News
- Financial: ForexFactory, Investing.com
- Cinema: Variety, Deadline, Hollywood Reporter, IMDb

### Supabase SPA Extraction Pattern
For React SPAs backed by Supabase (e.g. fundbase.ir):
1. Download JS bundle: `curl -s <site>/assets/index-*.js -H "Referer: <site>"`
2. Extract Supabase project ID from URL in JS
3. Extract anon key (JWT near supabase URL reference in JS)
4. Query REST API: `https://<project>.supabase.co/rest/v1/<table>?<params>`
5. Headers: `apikey: <key>`, `Authorization: Bearer <key>`

See `references/supabase-spa-extraction.md` for full worked example.

### Unicode Workaround
Entertainment news prompt was created in English to avoid U+200C injection block. Persian prompts work for LLM-driven jobs but must avoid invisible unicode characters.

## User Profile
- Name: Reza
- Role: Forex & crypto trader (PropFundingX)
- Interests: Financial markets, Iran-US war impact on markets, foreign cinema
- Language: Farsi
- Style: Concise responses
