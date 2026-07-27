#!/bin/bash
# Hermes Agent Backup Script
# Backs up vital Hermes data to GitHub repo

set -e

HERMES_DIR="$HOME/.hermes"
BACKUP_DIR="/data/hermes-backup-repo"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
DATE_TAG=$(date '+%Y-%m-%d_%H-%M')

# --- Cleanup old backup files ---
cd "$BACKUP_DIR"
rm -rf backup/

# --- Create backup directory ---
mkdir -p backup/memories
mkdir -p backup/skills
mkdir -p backup/cron
mkdir -p backup/sessions
mkdir -p backup/config

# --- Copy vital files ---

# Core memory store
cp -r "$HERMES_DIR/memories/"* backup/memories/ 2>/dev/null || true

# Skills (all custom + bundled)
cp -r "$HERMES_DIR/skills/"* backup/skills/ 2>/dev/null || true

# Cron jobs database
cp "$HERMES_DIR/cron/executions.db" backup/cron/ 2>/dev/null || true
cp "$HERMES_DIR/cron/.jobs.lock" backup/cron/ 2>/dev/null || true

# Sessions
cp "$HERMES_DIR/sessions/sessions.json" backup/sessions/ 2>/dev/null || true

# Config & personality
cp "$HERMES_DIR/config.yaml" backup/config/ 2>/dev/null || true
cp "$HERMES_DIR/SOUL.md" backup/config/ 2>/dev/null || true

# Skills prompt snapshot
cp "$HERMES_DIR/.skills_prompt_snapshot.json" backup/ 2>/dev/null || true

# Channel directory
cp "$HERMES_DIR/channel_directory.json" backup/ 2>/dev/null || true

# Gateway state
cp "$HERMES_DIR/gateway_state.json" backup/ 2>/dev/null || true

# Kanban database
cp "$HERMES_DIR/kanban.db" backup/ 2>/dev/null || true

# --- Write metadata ---
cat > backup/METADATA.md << EOF
# Hermes Backup

- **Timestamp:** $TIMESTAMP
- **Hostname:** $(hostname)
- **Hermes Version:** $(cat "$HERMES_DIR/.initialized" 2>/dev/null || echo "unknown")

## Included
- memories/ - Memory store
- skills/ - All skills
- cron/ - Cron job database
- sessions/ - Session data
- config/ - Configuration + SOUL.md
- kanban.db - Kanban database
- .skills_prompt_snapshot.json - Skills prompt cache
- channel_directory.json - Channel config
- gateway_state.json - Gateway state

## Excluded (sensitive/regenerable)
- state.db (contains tokens - excluded for GitHub push protection)
- .env (API keys)
- auth.json (auth tokens)
- audio_cache/, image_cache/ (regenerable)
- logs/ (not critical)
- cache/ (regenerable)
- models_dev_cache.json (regenerable)
EOF

# --- Git commit and push ---
cd "$BACKUP_DIR"
git add -A
if git diff --cached --quiet; then
    echo "No changes to backup."
    exit 0
fi

git commit -m "🔄 Backup: $DATE_TAG"
git push origin main 2>&1

echo "✅ Backup completed successfully at $TIMESTAMP"
