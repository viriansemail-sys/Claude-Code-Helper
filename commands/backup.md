Backup critical the system configs to NAS:

1. BACKUP_DIR="~/nas/system/backups/$(date +%Y-%m-%d_%H%M)"
2. mkdir -p "$BACKUP_DIR"/{gateway,claude-config,systemd}
3. rsync -av /opt/system/gateway/ "$BACKUP_DIR/gateway/" --exclude=__pycache__ --exclude=.venv --exclude=node_modules
4. rsync -av ~/.claude/CLAUDE.md ~/.claude/settings.json "$BACKUP_DIR/claude-config/"
5. cp -r ~/.claude/agents/ "$BACKUP_DIR/claude-config/agents/"
6. cp -r ~/.claude/commands/ "$BACKUP_DIR/claude-config/commands/"
7. rsync -av ~/.config/systemd/user/system-* "$BACKUP_DIR/systemd/" 2>/dev/null || echo "No systemd services found"
8. echo "Backup complete:" && du -sh "$BACKUP_DIR"
