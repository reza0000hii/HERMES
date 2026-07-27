# Session-Specific Patterns

## Backup to GitHub - Reza's Setup (2026-07-27)

Repository: https://github.com/reza0000hii/HERMES
Token: Classic PAT (ghp_...)

### Backup Script Location
- Original: /data/hermes-backup-repo/backup.sh
- Cron copy: ~/.hermes/scripts/hermes-backup.sh

### Files Excluded (GitHub Push Protection)
state.db contained PAT strings and was blocked by GH013. Added to .gitignore.

### Cron Jobs Created
| Job | ID | Schedule |
|-----|----|----------|
| Hermes Backup | 56ca43b8f22c | every 12h |
| Financial Calendar USD/EUR | 0bec365b366d | daily 10AM Iran (6:30 UTC) |
| Entertainment News | 43db40997624 | every 24h |
| Iran-US War News | f7408db9f8a0 | every 1h |
| Medicine Reminder | 52e91196380f | one-shot 18:00 Iran |

### Unicode Workaround
Entertainment news prompt was created in English to avoid U+200C injection block. Persian prompts work for LLM-driven jobs but must avoid invisible unicode characters.

## User Profile
- Name: Reza
- Role: Forex & crypto trader (PropFundingX)
- Interests: Financial markets, Iran-US war impact on markets, foreign cinema
- Language: Farsi
- Style: Concise responses
