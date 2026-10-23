# GCP Deploy Runbook — Loop + MeetNote

## Backups (nightly cron)
```bash
cat > /srv/backups/backup.sh <<'EOF'
#!/bin/bash
set -e
cd /opt/loop/deploy
DBPW=$(grep '^DB_ROOT_PASSWORD=' .env.gcp | cut -d= -f2-)
docker compose exec -T mysql mysqldump -uroot -p"$DBPW" loop_db | gzip > /srv/backups/loop_db_$(date +%F).sql.gz
rsync -a /srv/meetnote /srv/backups/
rsync -a /srv/recordings /srv/backups/
find /srv/backups -name '*.sql.gz' -mtime +14 -delete
EOF
chmod +x /srv/backups/backup.sh
(crontab -l 2>/dev/null; echo "0 2 * * * /srv/backups/backup.sh") | crontab -
```

## Update procedure
```bash
cd /opt/loop
git pull
cd /opt/loop/deploy
docker compose -f docker-compose.gcp.yml --env-file .env.gcp up -d --build
```

## Grow disk
```bash
sudo growpart /dev/sdb 1
sudo resize2fs /dev/sdb1
df -h /srv
```

## Troubleshooting
| Symptom | Fix |
|---|---|
| Out of memory | Upgrade VM to e2-standard-2 (8 GB) |
| LiveKit no video | Open UDP 50000-50020 on firewall |
| CORS error | Add origin to CORS_ORIGINS in .env.gcp, restart backend |
| MeetNote transcription stuck | Check service account user exists, check logs |
| Disk full | Grow disk (above) |
EOF
echo "Done"
