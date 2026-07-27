# Hermes Backup

- **Timestamp:** 2026-07-27 11:26:57
- **Hostname:** b4993185dac9
- **Hermes Version:** 2026-07-27T11:04:18Z

## Included
- memories/ - Memory store
- skills/ - All skills
- cron/ - Cron job database
- sessions/ - Session data
- config/ - Configuration + SOUL.md
- state.db - State database
- kanban.db - Kanban database
- .skills_prompt_snapshot.json - Skills prompt cache
- channel_directory.json - Channel config
- gateway_state.json - Gateway state

## Excluded (sensitive/regenerable)
- .env (API keys)
- auth.json (auth tokens)
- audio_cache/, image_cache/ (regenerable)
- logs/ (not critical)
- cache/ (regenerable)
- models_dev_cache.json (regenerable)
